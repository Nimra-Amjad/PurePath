import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purepath/features/home/models/daily_reflection.dart';
import 'package:purepath/features/home/models/day_summary.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/home/models/habit_model.dart';
import 'package:purepath/core/providers/home_provider.dart';
import 'package:purepath/core/repositories/home_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Firestore home repository
//
// Business-logic layer between the home/insights blocs and HomeProvider:
//
//   HomeBloc / ManageHabitsBloc / InsightsBloc
//       → FirestoreHomeRepository → HomeProvider
//
// The provider owns all raw Firestore access + the document schema. This
// class owns everything on top of that: model mapping, habit ordering,
// the week-summary join, and the streak walk.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreHomeRepository implements HomeRepository {
  final HomeProvider _provider;

  FirestoreHomeRepository({required HomeProvider provider})
      : _provider = provider;

  String? get _uid => _provider.currentUid;

  // ── HomeRepository implementation ──────────────────────────────────────────

  @override
  Future<List<HabitDefinition>> getAllHabits() async {
    final uid = _uid;
    if (uid == null) return const [];

    final docs = await _provider.fetchHabitDocs(uid);

    // Build the habits list and a side-map of createdAt millis in one pass.
    // Doing the lookup inline (instead of calling firstWhere/orElse later)
    // sidesteps a Firestore typing quirk: the static type is
    // `QueryDocumentSnapshot<Map<String, dynamic>>` but the runtime type is
    // the package-private `_JsonQueryDocumentSnapshot`, which makes
    // `orElse: () => docs.first` fail its subtype check at runtime.
    final createdAtById = <String, int>{};
    final habits = docs.map((doc) {
      final raw = doc.data();
      final ts = raw['createdAt'];
      createdAtById[doc.id] =
          ts is Timestamp ? ts.millisecondsSinceEpoch : 0;
      return HabitDefinition.fromMap({...raw, 'id': doc.id});
    }).toList();

    // Sort by createdAt client-side so older habits appear first.
    habits.sort((a, b) {
      final ta = createdAtById[a.id] ?? 0;
      final tb = createdAtById[b.id] ?? 0;
      return ta.compareTo(tb);
    });

    return habits;
  }

  @override
  Future<void> addHabit(HabitDefinition definition) async {
    final uid = _uid;
    if (uid == null) return;
    await _provider.createHabit(uid, definition.toMap());
  }

  @override
  Future<void> deleteHabit(String id) async {
    final uid = _uid;
    if (uid == null) return;

    // Just remove the habit definition. Stale entries in `insights` docs are
    // harmless: getSummaryForWeek joins on the live habits list, so any
    // orphaned ids in the array are simply ignored.
    await _provider.deleteHabit(uid, id);
  }

  @override
  Future<void> updateHabit(HabitDefinition definition) async {
    final uid = _uid;
    if (uid == null) return;
    await _provider.updateHabit(uid, definition.id, definition.toMap());
  }

  @override
  Future<void> setHabitProgress({
    required String habitId,
    required DateTime date,
    required double progress,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final hasDone = progress >= 1.0;

    // Read-modify-write the day's habits array so flipping one habit doesn't
    // overwrite the others' completion state.
    final data = await _provider.fetchDayDoc(uid, date);
    final habits = (data?['habits'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final entry = <String, dynamic>{
      'id': habitId,
      'hasDone': hasDone,
    };

    final idx = habits.indexWhere((e) => e['id'] == habitId);
    if (idx >= 0) {
      habits[idx] = entry;
    } else {
      habits.add(entry);
    }

    await _provider.writeDayHabits(uid, date, habits);
  }

  @override
  Future<Map<DateTime, DaySummary>> getSummaryForWeek(
    DateTime weekStart,
  ) async {
    final habits = await getAllHabits();

    // Completion data is best-effort: if Firestore rules don't allow reads
    // on `insights`, or the network blips, we still want to render the
    // habits list (just with everything unchecked) instead of erroring out
    // the entire home page.
    Map<String, bool> hasDoneByKey;
    try {
      hasDoneByKey = await _fetchWeekHasDone(weekStart);
    } catch (_) {
      hasDoneByKey = const {};
    }

    final result = <DateTime, DaySummary>{};

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final date = _dateOnly(weekStart.add(Duration(days: dayIndex)));

      final habitsForDay = habits
          .where((h) {
            final hasDone = hasDoneByKey[
                  '${h.id}_${date.millisecondsSinceEpoch}'
                ] ??
                false;
            return h.countsOn(date, completed: hasDone);
          })
          .map((definition) {
            final hasDone = hasDoneByKey[
                  '${definition.id}_${date.millisecondsSinceEpoch}'
                ] ??
                false;
            return HabitModel(
              id: definition.id,
              title: definition.title,
              subtitle: definition.subtitle,
              frequencyLabel: definition.frequencyLabel,
              progress: hasDone ? 1.0 : 0.0,
              colorValue: definition.colorValue,
            );
          })
          .toList();

      result[date] = DaySummary(date: date, habits: habitsForDay);
    }

    return result;
  }

  @override
  Future<Map<DateTime, Set<String>>> getCompletionHistory(int days) async {
    final uid = _uid;
    if (uid == null) return const {};

    // Best-effort: a rules/network hiccup should leave the heatmaps empty, not
    // blow up the whole insights screen.
    List<Map<String, dynamic>> docs;
    try {
      docs = await _provider.fetchRecentDayDocs(uid, days);
    } catch (_) {
      return const {};
    }

    final out = <DateTime, Set<String>>{};
    for (final data in docs) {
      final millis = (data['dateMillis'] as num?)?.toInt();
      if (millis == null) continue;
      final date = _dateOnly(DateTime.fromMillisecondsSinceEpoch(millis));

      final done = <String>{};
      final list = data['habits'] as List? ?? const [];
      for (final raw in list) {
        if (raw is! Map || raw['hasDone'] != true) continue;
        final id = raw['id'] as String? ?? '';
        if (id.isNotEmpty) done.add(id);
      }
      out[date] = done;
    }
    return out;
  }

  // ── Daily reflection (mood + note) ─────────────────────────────────────────

  @override
  Future<DailyReflection?> getReflection(DateTime date) async {
    final uid = _uid;
    if (uid == null) return null;

    // Best-effort, mirroring the other insights reads: a rules/network hiccup
    // should leave the reflection card in its empty state, not error the page.
    Map<String, dynamic>? data;
    try {
      data = await _provider.fetchDayDoc(uid, date);
    } catch (_) {
      return null;
    }

    if (data == null) return null;
    return DailyReflection.fromMap(data);
  }

  @override
  Future<void> setReflection({
    required DateTime date,
    required DailyReflection reflection,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    await _provider.writeDayReflection(
      uid,
      date,
      mood: reflection.mood?.name,
      note: reflection.note.trim(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Reads the 7 day-docs for the visible week and returns a
  /// `<habitId>_<dateMillis>` → hasDone map.
  Future<Map<String, bool>> _fetchWeekHasDone(DateTime weekStart) async {
    final uid = _uid;
    if (uid == null) return const {};

    final docsByDate = await _provider.fetchWeekDocs(uid, weekStart);

    final out = <String, bool>{};
    docsByDate.forEach((date, data) {
      if (data == null) return;
      final list = data['habits'] as List? ?? const [];
      for (final raw in list) {
        if (raw is! Map) continue;
        final habit = Map<String, dynamic>.from(raw);
        final habitId = habit['id'] as String? ?? '';
        final hasDone = habit['hasDone'] as bool? ?? false;
        if (habitId.isEmpty) continue;
        out['${habitId}_${date.millisecondsSinceEpoch}'] = hasDone;
      }
    });
    return out;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
