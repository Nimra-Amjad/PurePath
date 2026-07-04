import 'package:cloud_firestore/cloud_firestore.dart';
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

    final entry = <String, dynamic>{'id': habitId, 'hasDone': hasDone};

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
      final weekDayIndex = date.weekday - 1; // 0 = Mon … 6 = Sun

      final habitsForDay = habits
          .where((h) => h.isActiveOn(date))
          .where(
            (h) => h.isDaily || h.weekDays.contains(weekDayIndex),
          )
          .map((definition) {
            final hasDone = hasDoneByKey[
                  '${definition.id}_${date.millisecondsSinceEpoch}'
                ] ??
                false;
            return HabitModel(
              id: definition.id,
              title: definition.title,
              subtitle: definition.subtitle,
              category: definition.category,
              isDaily: definition.isDaily,
              progress: hasDone ? 1.0 : 0.0,
            );
          })
          .toList();

      result[date] = DaySummary(date: date, habits: habitsForDay);
    }

    return result;
  }

  @override
  Future<int> calculateCurrentStreak() async {
    final uid = _uid;
    if (uid == null) return 0;

    final today = _dateOnly(DateTime.now());

    // Anchor: today if it has any completion, else yesterday (grace window).
    DateTime cursor = today;
    bool cursorDone = await _isDayCompleted(uid, cursor);
    if (!cursorDone) {
      cursor = today.subtract(const Duration(days: 1));
      cursorDone = await _isDayCompleted(uid, cursor);
      if (!cursorDone) return 0;
    }

    // Walk backward day by day, counting consecutive completed days.
    // The 5000 cap matches the top badge threshold; it's just a safety
    // bound, not a reachable limit in practice.
    int streak = 0;
    while (cursorDone && streak < 5000) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
      cursorDone = await _isDayCompleted(uid, cursor);
    }
    return streak;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<bool> _isDayCompleted(String uid, DateTime date) async {
    final data = await _provider.fetchDayDoc(uid, date);
    if (data == null) return false;
    final habits = data['habits'] as List? ?? const [];
    for (final raw in habits) {
      if (raw is Map && raw['hasDone'] == true) return true;
    }
    return false;
  }

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
