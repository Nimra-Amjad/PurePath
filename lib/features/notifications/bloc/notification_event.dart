part of 'notification_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notification events
// ─────────────────────────────────────────────────────────────────────────────

sealed class NotificationEvent {
  const NotificationEvent();
}

/// Fired once on app start. Initializes the platform plugin and asks the OS
/// for notification permission.
final class InitializeNotifications extends NotificationEvent {
  const InitializeNotifications();
}

/// Re-schedules reminders for the supplied habits, or for every habit in the
/// repository when [habits] is null. Called after any add / update / delete
/// and once the home screen finishes its first load.
final class RescheduleHabitNotifications extends NotificationEvent {
  final List<HabitDefinition>? habits;
  const RescheduleHabitNotifications({this.habits});
}

/// Wipes every scheduled habit reminder. Used on logout.
final class CancelAllHabitNotifications extends NotificationEvent {
  const CancelAllHabitNotifications();
}
