part of 'planner_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Planner events
//
// sealed = exhaustive — the compiler flags any handler you forget.
// ─────────────────────────────────────────────────────────────────────────────

sealed class PlannerEvent {}

/// Triggered once when the planner screen first opens. Loads today's tasks.
final class PlannerStarted extends PlannerEvent {}

/// Triggered when the user taps a day tile in the calendar.
final class PlannerDateSelected extends PlannerEvent {
  final DateTime date;
  PlannerDateSelected(this.date);
}

/// Triggered when the user swipes to a different week.
/// [weekStart] is always the Monday of the newly visible week.
final class PlannerWeekChanged extends PlannerEvent {
  final DateTime weekStart;
  PlannerWeekChanged(this.weekStart);
}

/// Triggered when the month calendar sheet opens or flips to a new month.
/// Prefetches every day of [month] so its completion rings are populated.
/// [month] can be any day inside the target month.
final class PlannerMonthChanged extends PlannerEvent {
  final DateTime month;
  PlannerMonthChanged(this.month);
}

/// Triggered from the add-task sheet after tapping a slot's "+" button.
final class PlannerTaskAdded extends PlannerEvent {
  final DateTime date;
  final int hour;
  final String title;
  final String note;
  PlannerTaskAdded({
    required this.date,
    required this.hour,
    required this.title,
    required this.note,
  });
}

/// Triggered when an existing task is edited via the task sheet.
final class PlannerTaskUpdated extends PlannerEvent {
  final PlannerTask task;
  PlannerTaskUpdated(this.task);
}

/// Triggered when the user checks a task off (or un-checks it).
final class PlannerTaskToggled extends PlannerEvent {
  final String taskId;
  PlannerTaskToggled(this.taskId);
}

/// Triggered when the user deletes a task.
final class PlannerTaskDeleted extends PlannerEvent {
  final String taskId;
  PlannerTaskDeleted(this.taskId);
}

/// Triggered when the user moves a task to a different day and/or hour via the
/// card's "Move" menu. [task] is the original; [newDate] (local midnight) and
/// [newHour] (0–23) are the destination slot.
final class PlannerTaskMoved extends PlannerEvent {
  final PlannerTask task;
  final DateTime newDate;
  final int newHour;
  PlannerTaskMoved({
    required this.task,
    required this.newDate,
    required this.newHour,
  });
}
