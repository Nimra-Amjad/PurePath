part of 'notification_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notification states
// ─────────────────────────────────────────────────────────────────────────────

sealed class NotificationState {
  final bool permissionGranted;
  const NotificationState({this.permissionGranted = false});
}

final class NotificationInitial extends NotificationState {
  const NotificationInitial() : super(permissionGranted: false);
}

final class NotificationReady extends NotificationState {
  const NotificationReady({required super.permissionGranted});
}

final class NotificationFailure extends NotificationState {
  final String message;
  const NotificationFailure({required this.message})
      : super(permissionGranted: false);
}
