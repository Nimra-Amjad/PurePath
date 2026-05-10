part of 'notification_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notification events
// ─────────────────────────────────────────────────────────────────────────────

sealed class NotificationEvent {
  const NotificationEvent();
}

/// Fired once on app start. Initializes the plugin, asks for OS permission,
/// then syncs schedules with the user's current master-toggle value.
final class NotificationStarted extends NotificationEvent {
  const NotificationStarted();
}

/// Flips the master "reminders on/off" switch. Persists the value to the
/// user document and schedules or cancels OS reminders accordingly.
final class NotificationToggled extends NotificationEvent {
  final bool enabled;
  const NotificationToggled({required this.enabled});
}

/// Re-syncs the OS schedules with the current habit list. Fired after a
/// habit is added, edited, or deleted. Pass [habits] to skip the repository
/// fetch when the caller already has them on hand.
final class HabitNotificationsSynced extends NotificationEvent {
  final List<HabitDefinition>? habits;
  const HabitNotificationsSynced({this.habits});
}

/// Wipes every scheduled notification this app owns. Used on logout.
final class NotificationCleared extends NotificationEvent {
  const NotificationCleared();
}
