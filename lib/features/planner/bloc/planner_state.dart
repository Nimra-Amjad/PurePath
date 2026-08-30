part of 'planner_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Planner status
// ─────────────────────────────────────────────────────────────────────────────

enum PlannerStatus { loading, loaded, error }

// ─────────────────────────────────────────────────────────────────────────────
// Planner state
//
// Single immutable state class. [tasksByDate] is a cache keyed by date-only
// DateTimes (midnight): once a day is loaded it stays in memory while the
// planner tab is alive (the IndexedStack in the nav bar keeps it alive).
// ─────────────────────────────────────────────────────────────────────────────

class PlannerState {
  final PlannerStatus status;

  /// The day whose timeline is shown below the calendar.
  final DateTime selectedDate;

  /// The Monday of the week currently visible in the calendar.
  final DateTime visibleWeekStart;

  /// Cache of loaded days → their tasks (sorted by hour). Keys are date-only
  /// DateTimes (midnight).
  final Map<DateTime, List<PlannerTask>> tasksByDate;

  /// Non-null only when [status] == PlannerStatus.error.
  final String? errorMessage;

  const PlannerState({
    required this.status,
    required this.selectedDate,
    required this.visibleWeekStart,
    required this.tasksByDate,
    this.errorMessage,
  });

  /// Tasks for the currently selected day, or an empty list while it loads.
  List<PlannerTask> get selectedTasks => tasksByDate[selectedDate] ?? const [];

  PlannerState copyWith({
    PlannerStatus? status,
    DateTime? selectedDate,
    DateTime? visibleWeekStart,
    Map<DateTime, List<PlannerTask>>? tasksByDate,
    String? errorMessage,
  }) {
    return PlannerState(
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      visibleWeekStart: visibleWeekStart ?? this.visibleWeekStart,
      tasksByDate: tasksByDate ?? this.tasksByDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
