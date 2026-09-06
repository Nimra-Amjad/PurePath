part of 'insights_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Insights status
// ─────────────────────────────────────────────────────────────────────────────

enum InsightsStatus { loading, loaded, error }

// ─────────────────────────────────────────────────────────────────────────────
// Habit weekly stat
//
// Aggregated completion data for a single habit across the visible week.
// Used to populate the per-habit progress rows at the bottom of the screen.
// ─────────────────────────────────────────────────────────────────────────────

class HabitWeeklyStat {
  final String id;
  final String title;

  /// How many days within the visible week this habit was completed.
  final int completedDays;

  /// How many days within the visible week this habit was scheduled.
  final int totalDays;

  const HabitWeeklyStat({
    required this.id,
    required this.title,
    required this.completedDays,
    required this.totalDays,
  });

  /// Completion ratio (0.0 → 1.0). Drives the progress bar width.
  double get progress => totalDays == 0 ? 0.0 : completedDays / totalDays;
}

// ─────────────────────────────────────────────────────────────────────────────
// Insights state
//
// Single immutable class — the UI always reads from one place.
// [weekData] is a cache so already-loaded weeks aren't re-fetched on swipe.
// ─────────────────────────────────────────────────────────────────────────────

class InsightsState {
  /// Whether the bloc is loading, loaded, or errored.
  final InsightsStatus status;

  /// The Monday of the week currently visible on screen.
  final DateTime visibleWeekStart;

  /// Cache of all fetched summaries. Keys are date-only DateTimes (midnight).
  final Map<DateTime, DaySummary> weekData;

  /// All habits the user has created, in creation order. Drives the dot-grid
  /// collection cards (schedule + title + frequency all come from here).
  final List<HabitDefinition> habits;

  /// Per-day completion history for the heatmaps and monthly calendars:
  /// date (midnight) → set of habit ids completed that day. Covers the last
  /// [historyDaysLoaded] days ending today.
  final Map<DateTime, Set<String>> completionHistory;

  /// The first day (midnight) of the month currently visible on the Monthly tab.
  final DateTime visibleMonthStart;

  /// The year currently visible on the Yearly tab (e.g. 2026).
  final int visibleYear;

  /// How many days of [completionHistory] are currently loaded (ending today).
  /// Grows when the user pages back to a month/year older than the loaded window.
  final int historyDaysLoaded;

  /// Non-null only when [status] == InsightsStatus.error.
  final String? errorMessage;

  const InsightsState({
    required this.status,
    required this.visibleWeekStart,
    required this.visibleMonthStart,
    required this.visibleYear,
    required this.weekData,
    this.habits = const [],
    this.completionHistory = const {},
    this.historyDaysLoaded = 0,
    this.errorMessage,
  });

  // ── Derived data ───────────────────────────────────────────────────────────

  /// The Sunday of the visible week (weekStart + 6 days).
  DateTime get visibleWeekEnd => visibleWeekStart.add(const Duration(days: 6));

  /// Returns the 7 [DaySummary] entries for the visible week in Mon → Sun order.
  /// Days not yet loaded get an empty placeholder so the bar chart still renders.
  List<DaySummary> get visibleWeekSummaries {
    return List.generate(7, (i) {
      final date = visibleWeekStart.add(Duration(days: i));
      return weekData[date] ?? DaySummary(date: date, habits: []);
    });
  }

  // ── Weekly consistency (redesigned insights header) ────────────────────────

  /// Total habit-days completed across the visible week — the numerator of the
  /// consistency ring. e.g. 32 (32 of 42 scheduled habit-days were done).
  int get weekCompletedCount =>
      visibleWeekSummaries.fold(0, (sum, d) => sum + d.completedCount);

  /// Total habit-days scheduled across the visible week — the ring denominator.
  /// e.g. 6 habits over 7 days ≈ 42.
  int get weekScheduledCount =>
      visibleWeekSummaries.fold(0, (sum, d) => sum + d.totalCount);

  /// Overall consistency for the visible week (0.0 → 1.0):
  /// completed habit-days ÷ scheduled habit-days.
  double get weekConsistency =>
      weekScheduledCount == 0 ? 0.0 : weekCompletedCount / weekScheduledCount;

  /// Number of distinct habits scheduled at least once during the visible week
  /// — the "N habits tracked" label above the daily-completion bars.
  int get trackedHabitCount => habitWeeklyStats.length;

  /// The Monday of the week immediately before the visible one.
  DateTime get _previousWeekStart =>
      visibleWeekStart.subtract(const Duration(days: 7));

  /// True only when all 7 days of the previous week are cached, so a real
  /// week-over-week delta can be shown. (The bloc pre-loads this week.)
  bool get _hasPreviousWeek => List.generate(
    7,
    (i) => _previousWeekStart.add(Duration(days: i)),
  ).every(weekData.containsKey);

  /// Consistency (0.0 → 1.0) of the previous week, or null when it isn't
  /// loaded — in which case the "vs last week" chip is hidden.
  double? get previousWeekConsistency {
    if (!_hasPreviousWeek) return null;
    var completed = 0;
    var scheduled = 0;
    for (var i = 0; i < 7; i++) {
      final day = weekData[_previousWeekStart.add(Duration(days: i))];
      if (day == null) continue;
      completed += day.completedCount;
      scheduled += day.totalCount;
    }
    return scheduled == 0 ? 0.0 : completed / scheduled;
  }

  /// Change in consistency vs last week, in whole percentage points
  /// (e.g. +12). Null when the previous week isn't loaded yet.
  int? get consistencyDeltaPoints {
    final prev = previousWeekConsistency;
    if (prev == null) return null;
    return ((weekConsistency - prev) * 100).round();
  }

  /// Per-habit completion stats aggregated across the visible week.
  /// Each [HabitWeeklyStat] tells you "X of Y days done" for one habit.
  List<HabitWeeklyStat> get habitWeeklyStats {
    final Map<String, _MutableStat> accumulator = {};

    for (final day in visibleWeekSummaries) {
      for (final habit in day.habits) {
        final entry = accumulator.putIfAbsent(
          habit.id,
          () => _MutableStat(title: habit.title),
        );
        entry.totalDays += 1;
        if (habit.isCompleted) entry.completedDays += 1;
      }
    }

    return accumulator.entries.map((e) {
      return HabitWeeklyStat(
        id: e.key,
        title: e.value.title,
        completedDays: e.value.completedDays,
        totalDays: e.value.totalDays,
      );
    }).toList();
  }

  // ── Monthly overview ────────────────────────────────────────────────────────

  /// Today's date with the time stripped (local midnight).
  DateTime get _todayDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Number of days in the visible month (e.g. 30 for September).
  int get daysInVisibleMonth =>
      DateTime(visibleMonthStart.year, visibleMonthStart.month + 1, 0).day;

  /// Per-day completion stats for every day of the visible month, day 1 → last.
  /// Future days (after today) still report their scheduled habit-days —
  /// [isFuture] just flags that [completed] can only ever be 0 so far.
  List<MonthDayStat> get monthDayStats {
    final today = _todayDate;
    return List.generate(daysInVisibleMonth, (i) {
      final date = DateTime(
        visibleMonthStart.year,
        visibleMonthStart.month,
        i + 1,
      );
      final completedIds = completionHistory[date] ?? const <String>{};
      var scheduled = 0;
      var completed = 0;
      for (final h in habits) {
        final isCompleted = completedIds.contains(h.id);
        if (h.countsOn(date, completed: isCompleted)) {
          scheduled += 1;
          if (isCompleted) completed += 1;
        }
      }
      return MonthDayStat(
        date: date,
        scheduled: scheduled,
        completed: completed,
        isFuture: date.isAfter(today),
      );
    });
  }

  /// Total completed habit-days across the visible month ("DAYS DONE").
  int get monthCompletedCount =>
      monthDayStats.fold(0, (sum, d) => sum + d.completed);

  /// Total scheduled habit-days across the visible month.
  int get monthScheduledCount =>
      monthDayStats.fold(0, (sum, d) => sum + d.scheduled);

  /// Overall month completion (0.0 → 1.0) — the "MONTH MET" percentage.
  double get monthMet =>
      monthScheduledCount == 0 ? 0.0 : monthCompletedCount / monthScheduledCount;

  /// Per-habit month completion, one entry per habit scheduled at least once
  /// this month — drives the per-habit calendars.
  List<HabitMonthStat> get habitMonthStats {
    final result = <HabitMonthStat>[];
    for (final habit in habits) {
      var scheduled = 0;
      var completed = 0;
      for (var i = 0; i < daysInVisibleMonth; i++) {
        final date = DateTime(
          visibleMonthStart.year,
          visibleMonthStart.month,
          i + 1,
        );
        final isCompleted = completionHistory[date]?.contains(habit.id) ?? false;
        if (habit.countsOn(date, completed: isCompleted)) {
          scheduled += 1;
          if (isCompleted) completed += 1;
        }
      }
      if (scheduled == 0) continue;
      result.add(
        HabitMonthStat(
          habit: habit,
          scheduled: scheduled,
          completed: completed,
        ),
      );
    }
    return result;
  }

  /// Number of habits tracked (scheduled at least once) this month.
  int get monthTrackedHabits => habitMonthStats.length;

  /// Habits completed on every scheduled day this month ("PERFECT").
  int get monthPerfectHabits =>
      habitMonthStats.where((s) => s.isPerfect).length;

  // ── Yearly overview ─────────────────────────────────────────────────────────

  /// Per-habit completion across the visible year (Jan 1 → Dec 31), including
  /// days still to come. One entry per habit scheduled at least once — drives
  /// the per-habit year grids.
  List<HabitYearStat> get habitYearStats {
    final end = DateTime(visibleYear, 12, 31);
    final start = DateTime(visibleYear, 1, 1);

    final result = <HabitYearStat>[];
    for (final habit in habits) {
      var scheduled = 0;
      var completed = 0;
      var date = start;
      while (!date.isAfter(end)) {
        final isCompleted = completionHistory[date]?.contains(habit.id) ?? false;
        if (habit.countsOn(date, completed: isCompleted)) {
          scheduled += 1;
          if (isCompleted) completed += 1;
        }
        date = date.add(const Duration(days: 1));
      }
      if (scheduled == 0) continue;
      result.add(
        HabitYearStat(habit: habit, scheduled: scheduled, completed: completed),
      );
    }
    return result;
  }

  /// Total completed habit-days across the visible year — the big
  /// "DAYS COMPLETED IN {year}" number.
  int get yearDaysCompleted =>
      habitYearStats.fold(0, (sum, s) => sum + s.completed);

  // ── copyWith ───────────────────────────────────────────────────────────────

  InsightsState copyWith({
    InsightsStatus? status,
    DateTime? visibleWeekStart,
    DateTime? visibleMonthStart,
    int? visibleYear,
    Map<DateTime, DaySummary>? weekData,
    List<HabitDefinition>? habits,
    Map<DateTime, Set<String>>? completionHistory,
    int? historyDaysLoaded,
    String? errorMessage,
  }) {
    return InsightsState(
      status: status ?? this.status,
      visibleWeekStart: visibleWeekStart ?? this.visibleWeekStart,
      visibleMonthStart: visibleMonthStart ?? this.visibleMonthStart,
      visibleYear: visibleYear ?? this.visibleYear,
      weekData: weekData ?? this.weekData,
      habits: habits ?? this.habits,
      completionHistory: completionHistory ?? this.completionHistory,
      historyDaysLoaded: historyDaysLoaded ?? this.historyDaysLoaded,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Internal mutable accumulator — keeps [habitWeeklyStats] readable.
class _MutableStat {
  final String title;
  int completedDays = 0;
  int totalDays = 0;

  _MutableStat({required this.title});
}

// ─────────────────────────────────────────────────────────────────────────────
// Month day stat
//
// One calendar day's completion for the monthly heatmap. [isFuture] days (after
// today) carry no data and render empty.
// ─────────────────────────────────────────────────────────────────────────────

class MonthDayStat {
  final DateTime date;
  final int scheduled;
  final int completed;
  final bool isFuture;

  const MonthDayStat({
    required this.date,
    required this.scheduled,
    required this.completed,
    required this.isFuture,
  });

  /// Completion ratio for the day (0.0 → 1.0). Drives the heatmap tint.
  double get progress => scheduled == 0 ? 0.0 : completed / scheduled;

  /// True when every scheduled habit was completed on this day.
  bool get isFull => scheduled > 0 && completed >= scheduled;
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit month stat
//
// One habit's completion across the visible month — powers the per-habit
// calendars and the "PERFECT" count.
// ─────────────────────────────────────────────────────────────────────────────

class HabitMonthStat {
  final HabitDefinition habit;
  final int scheduled;
  final int completed;

  const HabitMonthStat({
    required this.habit,
    required this.scheduled,
    required this.completed,
  });

  double get progress => scheduled == 0 ? 0.0 : completed / scheduled;

  /// True when the habit was completed on every day it was scheduled this month.
  bool get isPerfect => scheduled > 0 && completed >= scheduled;
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit year stat
//
// One habit's completion across the visible year — powers the per-habit
// year-long contribution grids.
// ─────────────────────────────────────────────────────────────────────────────

class HabitYearStat {
  final HabitDefinition habit;
  final int scheduled;
  final int completed;

  const HabitYearStat({
    required this.habit,
    required this.scheduled,
    required this.completed,
  });

  double get progress => scheduled == 0 ? 0.0 : completed / scheduled;
}
