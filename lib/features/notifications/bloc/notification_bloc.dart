import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:purepath/core/repositories/user_repository.dart';
import 'package:purepath/core/services/notification_service.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/home/repositories/home_repository.dart';

part 'notification_event.dart';
part 'notification_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationBloc
//
// Owns the notification lifecycle for the whole app:
//
//   • InitializeNotifications — runs once at app start, sets up the plugin
//     and asks for OS-level permission.
//   • RescheduleHabitNotifications — re-schedules a reminder for every habit
//     that has a non-empty reminderTime. Triggered after add / update / delete
//     and after the home screen first loads habits.
//   • CancelAllHabitNotifications — wipes every scheduled reminder (e.g. on
//     logout).
//
// The bloc itself stays thin — the heavy lifting lives in [NotificationService].
// ─────────────────────────────────────────────────────────────────────────────

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({
    required this.notificationService,
    required this.homeRepository,
    required this.userRepository,
  }) : super(const NotificationInitial()) {
    on<InitializeNotifications>(_onInitialize);
    on<RescheduleHabitNotifications>(_onReschedule);
    on<CancelAllHabitNotifications>(_onCancelAll);
  }

  final NotificationService notificationService;
  final HomeRepository homeRepository;
  final UserRepository userRepository;

  /// Honors the user-level master toggle stored on [UserModel]. When the user
  /// flips it off in profile/onboarding we should stop scheduling regardless
  /// of per-habit reminderTime values. Defaults to false until the user has
  /// completed onboarding so we don't fire reminders for users who never
  /// opted in.
  bool get _masterEnabled =>
      userRepository.localUser?.notificationsEnabled ?? false;

  Future<void> _onInitialize(
    InitializeNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (!notificationService.isInitialized) {
        await notificationService.initializePlatformNotifications();
      }
      final granted = await notificationService.requestNotificationPermission();
      emit(NotificationReady(permissionGranted: granted));

      if (granted) {
        // After permission is granted, sync any existing habit reminders so
        // newly installed users (or fresh logins) immediately have their
        // schedules in place without waiting for an add/edit.
        add(RescheduleHabitNotifications());
      }
    } catch (e) {
      debugPrint('NotificationBloc.initialize error: $e');
      emit(NotificationFailure(message: e.toString()));
    }
  }

  Future<void> _onReschedule(
    RescheduleHabitNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // If the user has the master switch off, wipe any leftover schedules
      // and stop. This keeps the profile toggle and the actual OS-level
      // schedules consistent — a stale reminder from before they disabled
      // would otherwise still fire.
      if (!_masterEnabled) {
        await notificationService.cancelAllHabitNotifications();
        emit(NotificationReady(permissionGranted: state.permissionGranted));
        return;
      }

      final habits = event.habits ?? await homeRepository.getAllHabits();
      await notificationService.scheduleHabitNotifications(habits);
      emit(NotificationReady(permissionGranted: state.permissionGranted));
    } catch (e) {
      debugPrint('NotificationBloc.reschedule error: $e');
      // Silent failure — don't block the UI; the user can retry by
      // adding/editing a habit.
    }
  }

  Future<void> _onCancelAll(
    CancelAllHabitNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await notificationService.cancelAllHabitNotifications();
      emit(NotificationReady(permissionGranted: state.permissionGranted));
    } catch (e) {
      debugPrint('NotificationBloc.cancelAll error: $e');
    }
  }
}
