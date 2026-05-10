import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:purepath/core/repositories/user_repository.dart';
import 'package:purepath/core/services/notification_service.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/home/repositories/home_repository.dart';

part 'notification_event.dart';
part 'notification_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notification BLoC
//
// The single owner of the notifications feature. Pages don't talk to the
// service or to Firestore directly — they dispatch one of four events:
//
//   • NotificationStarted        — fires once at app start
//   • NotificationToggled        — flips the master "reminders on/off" switch
//                                  (used by profile + onboarding)
//   • HabitNotificationsSynced   — re-syncs OS schedules after add/edit/delete
//   • NotificationCleared        — wipes everything (used on logout)
//
// The bloc owns three responsibilities:
//   1. Plugin lifecycle    — initialize + permission via NotificationService.
//   2. Master toggle       — write to UserRepository (local + Firestore).
//   3. Schedule sync       — replace OS schedules from the latest habit list,
//                            but only when the master toggle is on.
//
// Pattern mirrors PurePath's other BLoCs (HomeBloc, ManageHabitsBloc):
// a single state class with a status enum + copyWith.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({
    required NotificationService notificationService,
    required HomeRepository homeRepository,
    required UserRepository userRepository,
  })  : _service = notificationService,
        _homeRepository = homeRepository,
        _userRepository = userRepository,
        super(const NotificationState()) {
    on<NotificationStarted>(_onStarted);
    on<NotificationToggled>(_onToggled);
    on<HabitNotificationsSynced>(_onSynced);
    on<NotificationCleared>(_onCleared);
  }

  final NotificationService _service;
  final HomeRepository _homeRepository;
  final UserRepository _userRepository;

  /// Reads the master switch from the local user model, defaulting to false
  /// so users who haven't completed onboarding don't get reminders.
  bool get _isMasterEnabled =>
      _userRepository.localUser?.notificationsEnabled ?? false;

  // ── Event handlers ────────────────────────────────────────────────────────

  /// Initializes the plugin, asks for OS permission, then syncs schedules
  /// with the user's master toggle. Called once at app start.
  Future<void> _onStarted(
    NotificationStarted event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    try {
      await _service.initialize();
      final granted = await _service.requestPermission();

      // If permission is denied or the master is off, make sure no stale
      // schedules survive from a previous session.
      if (!granted || !_isMasterEnabled) {
        await _service.cancelAll();
      } else {
        final habits = await _homeRepository.getAllHabits();
        await _service.scheduleHabits(habits);
      }

      emit(state.copyWith(
        status: NotificationStatus.ready,
        isPermissionGranted: granted,
        isMasterEnabled: _isMasterEnabled,
      ));
    } catch (e) {
      debugPrint('NotificationBloc.started error: $e');
      emit(state.copyWith(
        status: NotificationStatus.failure,
        errorMessage: 'Could not set up reminders.',
      ));
    }
  }

  /// Flips the master switch end-to-end:
  ///   1. Persist to the user document (local + Firestore).
  ///   2. Schedule or cancel OS reminders accordingly.
  ///
  /// Called by both the profile reminders page and the onboarding flow.
  Future<void> _onToggled(
    NotificationToggled event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    try {
      final ok = await _userRepository.setNotificationsEnabled(event.enabled);

      if (event.enabled) {
        // Make sure the OS will let us actually post — if the user denied
        // permission earlier, asking again surfaces the system prompt.
        final granted = state.isPermissionGranted ||
            await _service.requestPermission();
        if (granted) {
          final habits = await _homeRepository.getAllHabits();
          await _service.scheduleHabits(habits);
        }
        emit(state.copyWith(
          status: ok ? NotificationStatus.ready : NotificationStatus.failure,
          isPermissionGranted: granted,
          isMasterEnabled: event.enabled,
          errorMessage: ok ? null : 'Could not save your preference.',
        ));
      } else {
        await _service.cancelAll();
        emit(state.copyWith(
          status: ok ? NotificationStatus.ready : NotificationStatus.failure,
          isMasterEnabled: event.enabled,
          errorMessage: ok ? null : 'Could not save your preference.',
        ));
      }
    } catch (e) {
      debugPrint('NotificationBloc.toggled error: $e');
      emit(state.copyWith(
        status: NotificationStatus.failure,
        errorMessage: 'Could not update reminders.',
      ));
    }
  }

  /// Re-syncs the OS schedules with the latest habit list. Called after a
  /// habit is added, edited, or deleted. No-op if the master is off — the
  /// stale schedules were already wiped when the master was switched off.
  Future<void> _onSynced(
    HabitNotificationsSynced event,
    Emitter<NotificationState> emit,
  ) async {
    if (!_isMasterEnabled) return;

    try {
      final habits = event.habits ?? await _homeRepository.getAllHabits();
      await _service.scheduleHabits(habits);
      emit(state.copyWith(status: NotificationStatus.ready));
    } catch (e) {
      // Silent failure — pages already showed the success snackbar for the
      // CRUD action; surfacing a second error here would be noisy.
      debugPrint('NotificationBloc.synced error: $e');
    }
  }

  /// Wipes every scheduled notification this app owns. Used on logout so a
  /// signed-out device doesn't keep firing reminders for a user who's gone.
  Future<void> _onCleared(
    NotificationCleared event,
    Emitter<NotificationState> emit,
  ) async {
    await _service.cancelAll();
    emit(state.copyWith(isMasterEnabled: false));
  }
}
