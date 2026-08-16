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

    // Stamp the day the completion was actually marked. The streak counts a
    // completion only if this equals the habit's own day (on-time); a late
    // backfill is still recorded but won't repair a broken streak.
    final entry = <String, dynamic>{
      'id': habitId,
      'hasDone': hasDone,
      if (hasDone)
        'doneAt': _dateOnly(DateTime.now()).millisecondsSinceEpoch,
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

  @override
  Future<int> calculateCurrentStreak() async {
    final uid = _uid;
    if (uid == null) return 0;
    return _streakWith(uid);
  }

  /// A break is only restorable if the gap *starts* within this many days of
  /// today. After this the banner disappears and the streak just continues as
  /// the fresh run.
  static const _maxBreakAgeDays = 4;

  /// How far back to classify days. One past the max break age so we can also
  /// see the previous run sitting just below a 14-day-old gap.
  static const _restoreWindow = _maxBreakAgeDays + 1;

  @override
  Future<StreakBreak?> findRestorableStreakBreak() async {
    final uid = _uid;
    if (uid == null) return null;

    final today = _dateOnly(DateTime.now());

    // Classify the recent window once (index 0 = today). Looks for the shape
    //   [current run] [gap] [previous run]
    // so restore stays available even after the user logs more days *past* the
    // gap — the gap keeps their earlier streak separated until it's frozen.
    final done = <bool>[];
    for (int i = 0; i <= _restoreWindow; i++) {
      done.add(await _isDayCompleted(uid, today.subtract(Duration(days: i))));
    }

    // Anchor of the current run: today if done, else yesterday (grace window).
    int i = done[0] ? 0 : (done[1] ? 1 : -1);
    if (i < 0) return null; // neither today nor yesterday done — nothing live

    // Walk down the current run to the first missed day (top of the gap).
    while (i <= _restoreWindow && done[i]) {
      i++;
    }
    // No gap in range → streak is healthy. Gap too old → not restorable.
    if (i > _restoreWindow || i > _maxBreakAgeDays) return null;

    // Collect the consecutive missed days (the gap).
    final missed = <DateTime>[];
    while (i <= _restoreWindow && !done[i]) {
      missed.add(today.subtract(Duration(days: i)));
      i++;
    }

    // Need a completed run right below the gap to reconnect to.
    if (i > _restoreWindow || missed.isEmpty) return null;

    // What the streak becomes once those days are frozen.
    final recovered = await _streakWith(uid, extraFrozen: missed.toSet());
    if (recovered <= 0) return null;

    return StreakBreak(missedDates: missed, recoveredStreak: recovered);
  }

  @override
  Future<void> restoreStreak(List<DateTime> dates) async {
    final uid = _uid;
    if (uid == null) return;
    for (final date in dates) {
      await _provider.freezeDay(uid, _dateOnly(date));
    }
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

  /// Counts the consecutive completed days ending at today (or yesterday, as a
  /// grace window). [extraFrozen] lets callers simulate a restore without
  /// writing anything — those dates are treated as completed.
  Future<int> _streakWith(
    String uid, {
    Set<DateTime> extraFrozen = const {},
  }) async {
    final today = _dateOnly(DateTime.now());

    DateTime cursor = today;
    bool done = await _isDayCompleted(uid, cursor, extraFrozen: extraFrozen);
    if (!done) {
      cursor = today.subtract(const Duration(days: 1));
      done = await _isDayCompleted(uid, cursor, extraFrozen: extraFrozen);
      if (!done) return 0;
    }

    // The 5000 cap matches the top badge threshold; a safety bound only.
    int streak = 0;
    while (done && streak < 5000) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
      done = await _isDayCompleted(uid, cursor, extraFrozen: extraFrozen);
    }
    return streak;
  }

  /// A day counts toward the streak if it was frozen (streak-restored) or has
  /// at least one habit that was completed **on time** — i.e. marked on its own
  /// day. A late backfill (marked on a later day) is still recorded and shown
  /// in the UI, but must not silently repair a broken streak; that's what the
  /// Pro restore is for. Legacy completions without a `doneAt` are treated as
  /// on-time so existing streaks aren't disrupted.
  ///
  /// [extraFrozen] treats extra dates as frozen (restore simulations).
  Future<bool> _isDayCompleted(
    String uid,
    DateTime date, {
    Set<DateTime> extraFrozen = const {},
  }) async {
    if (extraFrozen.contains(date)) return true;
    final data = await _provider.fetchDayDoc(uid, date);
    if (data == null) return false;
    if (data['frozen'] == true) return true;
    final habits = data['habits'] as List? ?? const [];
    for (final raw in habits) {
      if (raw is! Map || raw['hasDone'] != true) continue;
      final doneAt = raw['doneAt'];
      if (doneAt == null) return true; // legacy → assume on-time
      final doneAtDate = _dateOnly(
        DateTime.fromMillisecondsSinceEpoch((doneAt as num).toInt()),
      );
      if (!doneAtDate.isAfter(date)) return true; // completed on its own day
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
