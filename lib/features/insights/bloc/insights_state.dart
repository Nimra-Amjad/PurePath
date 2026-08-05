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
  final HabitCategory category;

  /// How many days within the visible week this habit was completed.
  final int completedDays;

  /// How many days within the visible week this habit was scheduled.
  final int totalDays;

  const HabitWeeklyStat({
    required this.id,
    required this.title,
    required this.category,
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

  /// Per-day completion history for the collection heatmaps: date (midnight) →
  /// set of habit ids completed that day. Covers roughly the last few months.
  final Map<DateTime, Set<String>> completionHistory;

  /// Non-null only when [status] == InsightsStatus.error.
  final String? errorMessage;

  const InsightsState({
    required this.status,
    required this.visibleWeekStart,
    required this.weekData,
    this.habits = const [],
    this.completionHistory = const {},
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

  /// Per-habit completion stats aggregated across the visible week.
  /// Each [HabitWeeklyStat] tells you "X of Y days done" for one habit.
  List<HabitWeeklyStat> get habitWeeklyStats {
    final Map<String, _MutableStat> accumulator = {};

    for (final day in visibleWeekSummaries) {
      for (final habit in day.habits) {
        final entry = accumulator.putIfAbsent(
          habit.id,
          () => _MutableStat(title: habit.title, category: habit.category),
        );
        entry.totalDays += 1;
        if (habit.isCompleted) entry.completedDays += 1;
      }
    }

    return accumulator.entries.map((e) {
      return HabitWeeklyStat(
        id: e.key,
        title: e.value.title,
        category: e.value.category,
        completedDays: e.value.completedDays,
        totalDays: e.value.totalDays,
      );
    }).toList();
  }

  // ── copyWith ───────────────────────────────────────────────────────────────

  InsightsState copyWith({
    InsightsStatus? status,
    DateTime? visibleWeekStart,
    Map<DateTime, DaySummary>? weekData,
    List<HabitDefinition>? habits,
    Map<DateTime, Set<String>>? completionHistory,
    String? errorMessage,
  }) {
    return InsightsState(
      status: status ?? this.status,
      visibleWeekStart: visibleWeekStart ?? this.visibleWeekStart,
      weekData: weekData ?? this.weekData,
      habits: habits ?? this.habits,
      completionHistory: completionHistory ?? this.completionHistory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Internal mutable accumulator — keeps [habitWeeklyStats] readable.
class _MutableStat {
  final String title;
  final HabitCategory category;
  int completedDays = 0;
  int totalDays = 0;

  _MutableStat({required this.title, required this.category});
}
