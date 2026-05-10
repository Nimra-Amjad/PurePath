part of 'notification_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notification state
//
// Single-class state with a status enum + copyWith — same shape as HomeState
// and ManageHabitsState elsewhere in the project.
// ─────────────────────────────────────────────────────────────────────────────

enum NotificationStatus {
  /// Bloc was just constructed; no work has run yet.
  initial,

  /// A long-running event (init, toggle) is in flight.
  loading,

  /// Plugin is initialized and (if the master is on) schedules are in sync.
  ready,

  /// The last operation hit an error — see [NotificationState.errorMessage].
  failure,
}

class NotificationState {
  /// Lifecycle status. Pages can branch on this if they want to show a
  /// loading indicator while the master toggle persists.
  final NotificationStatus status;

  /// True once the OS has granted notification permission. We mostly use
  /// this to surface a hint in the UI; scheduling itself is gated by
  /// [isMasterEnabled].
  final bool isPermissionGranted;

  /// The user-facing master switch. Mirrors `UserModel.notificationsEnabled`
  /// so any widget can read it from this bloc instead of UserBloc.
  final bool isMasterEnabled;

  /// Human-readable message for the most recent failure. Null on success.
  final String? errorMessage;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.isPermissionGranted = false,
    this.isMasterEnabled = false,
    this.errorMessage,
  });

  NotificationState copyWith({
    NotificationStatus? status,
    bool? isPermissionGranted,
    bool? isMasterEnabled,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isMasterEnabled: isMasterEnabled ?? this.isMasterEnabled,
      errorMessage: errorMessage,
    );
  }
}
