import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/enums/onboarding_enums.dart';
import 'package:purepath/core/repositories/firebase_auth_repository.dart';
import 'package:purepath/core/repositories/user_repository.dart';
import 'package:purepath/features/auth/model/user_model.dart';

part 'user_event.dart';
part 'user_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserBloc
//
// Global BLoC — lives at the app root inside DI so any widget can read it via
// context.read<UserBloc>() or context.watch<UserBloc>().
//
// Responsibilities:
//   • Auth  — login, signup, logout
//   • Session restore — LoadUser (Splash checks Firebase session)
//   • Onboarding save — SaveOnboardingData writes goal/challenge to Firestore
//   • Stream sync — keeps UserProvider in sync with Firebase user changes
//
// Pattern mirrors MacroPath's UserBloc.
// ─────────────────────────────────────────────────────────────────────────────

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc({required this.firebaseAuthRepository, required this.userRepository})
    : super(const UserInitial()) {
    _handleProviderSubscriptions();

    on<LoginRequested>(_onLoginRequested);
    on<SignupRequested>(_onSignupRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<LoadUser>(_onLoadUser);
    on<SaveOnboardingData>(_onSaveOnboardingData);
    on<PostHidden>(_onPostHidden);
    on<PostUnhidden>(_onPostUnhidden);
    on<UserBlocked>(_onUserBlocked);
    on<UserUnblocked>(_onUserUnblocked);
    on<_SyncFirebaseUser>(_onSyncFirebaseUser);
    on<_SyncLocalUser>(_onSyncLocalUser);
  }

  final FirebaseAuthRepository firebaseAuthRepository;
  final UserRepository userRepository;

  late final StreamSubscription<User?> _firebaseUserSub;
  late final StreamSubscription<UserModel?> _localUserSub;

  // ── Stream subscriptions ───────────────────────────────────────────────────

  void _handleProviderSubscriptions() {
    _firebaseUserSub = userRepository.firebaseUserStream.listen(
      (user) => add(_SyncFirebaseUser(user)),
    );
    _localUserSub = userRepository.userModelStream.listen(
      (user) => add(_SyncLocalUser(user)),
    );
  }

  // ── Internal sync handlers ─────────────────────────────────────────────────

  void _onSyncFirebaseUser(_SyncFirebaseUser event, Emitter<UserState> emit) {
    final current = state;
    if (current is UserLoaded) {
      emit(UserLoaded(user: current.user!, firebaseUser: event.user));
    }
  }

  void _onSyncLocalUser(_SyncLocalUser event, Emitter<UserState> emit) {
    if (event.user == null) return;
    final current = state;
    if (current is UserLoaded) {
      emit(UserLoaded(user: event.user!, firebaseUser: current.firebaseUser));
    }
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await firebaseAuthRepository.login(
        email: event.email,
        password: event.password,
      );
      final fbUser = firebaseAuthRepository.firebaseUser;
      userRepository.updateFirebaseUser(fbUser);
      userRepository.updateLocalUser(user);
      emit(UserSignedIn(user: user, firebaseUser: fbUser));
    } catch (e) {
      emit(AuthFailure(_mapError(e)));
    }
  }

  Future<void> _onSignupRequested(
    SignupRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await firebaseAuthRepository.signup(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
      );
      final fbUser = firebaseAuthRepository.firebaseUser;
      userRepository.updateFirebaseUser(fbUser);
      userRepository.updateLocalUser(user);
      emit(UserSignedUp(user: user, firebaseUser: fbUser));
    } catch (e) {
      emit(AuthFailure(_mapError(e)));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<UserState> emit,
  ) async {
    await firebaseAuthRepository.logout();
    userRepository.updateLocalUser(null);
    userRepository.updateFirebaseUser(null);
    emit(const UserLoggedOut());
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(const PasswordResetLoading());
    try {
      await firebaseAuthRepository.sendPasswordResetEmail(event.email);
      emit(PasswordResetSent(event.email));
    } catch (e) {
      emit(PasswordResetFailure(_mapError(e)));
    }
  }

  // ── Session restore (Splash) ───────────────────────────────────────────────

  Future<void> _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
    emit(const AuthLoading());
    try {
      final fbUser = event.firebaseUser;

      if (fbUser == null) {
        emit(const UserNotFound());
        return;
      }

      userRepository.updateFirebaseUser(fbUser);

      final userDoc = await userRepository.getUserDocumentByUid();
      if (userDoc == null) {
        emit(const UserNotFound());
        return;
      }

      userRepository.updateLocalUser(userDoc);

      if (userDoc.onboardingStatus == OnboardingStatus.completed) {
        emit(UserSessionRestored(user: userDoc, firebaseUser: fbUser));
      } else {
        emit(UserOnboardingIncomplete(user: userDoc, firebaseUser: fbUser));
      }
    } catch (e) {
      debugPrint('UserBloc.LoadUser error: $e');
      emit(const UserNotFound());
    }
  }

  // ── Onboarding save ────────────────────────────────────────────────────────

  Future<void> _onSaveOnboardingData(
    SaveOnboardingData event,
    Emitter<UserState> emit,
  ) async {
    try {
      final fbUser = userRepository.firebaseUser;
      final currentUser = userRepository.localUser;

      // Update the local model FIRST so any listener (profile tab, home
      // greeting) sees the new preferences before the Firestore round-trip
      // completes. The `notificationsEnabled` flag is *not* set here —
      // NotificationBloc owns that field end-to-end via NotificationToggled.
      final updatedUser = (currentUser ?? UserModel.empty()).copyWith(
        onboardingStatus: OnboardingStatus.completed,
        username: event.username,
        goal: event.goal,
        challenge: event.challenge,
        activityLevel: event.activityLevel,
      );
      userRepository.updateLocalUser(updatedUser);

      await userRepository.updateUserDocument({
        'username': event.username,
        'goal': event.goal,
        'challenge': event.challenge,
        'activityLevel': event.activityLevel,
        'onboardingStatus': OnboardingStatus.completed.toValue(),
        'allowAccess': false,
      });

      emit(OnboardingCompleted(user: updatedUser, firebaseUser: fbUser));
    } catch (e) {
      debugPrint('UserBloc.SaveOnboardingData error: $e');
      // Non-fatal: navigate to welcome anyway; the user shouldn't be blocked.
      final current = state;
      if (current is UserLoaded) {
        emit(
          OnboardingCompleted(
            user: current.user!,
            firebaseUser: current.firebaseUser,
          ),
        );
      }
    }
  }

  // ── Community moderation ───────────────────────────────────────────────────
  //
  // These simply delegate to UserRepository. It optimistically updates the
  // local user, whose stream emission comes back as [_SyncLocalUser] and
  // re-emits UserLoaded with the new block/hide lists — so the community feed
  // (which reads these lists) rebuilds automatically. No state is emitted here.

  Future<void> _onPostHidden(PostHidden event, Emitter<UserState> emit) {
    return userRepository.hidePost(event.postId);
  }

  Future<void> _onPostUnhidden(PostUnhidden event, Emitter<UserState> emit) {
    return userRepository.unhidePost(event.postId);
  }

  Future<void> _onUserBlocked(UserBlocked event, Emitter<UserState> emit) {
    return userRepository.blockUser(event.userId);
  }

  Future<void> _onUserUnblocked(UserUnblocked event, Emitter<UserState> emit) {
    return userRepository.unblockUser(event.userId);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _mapError(Object e) {
    final code = e is FirebaseAuthException ? e.code : e.toString();

    switch (code) {
      // ── Login errors ──────────────────────────────────────────────────────
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      // Flutter Firebase SDK v5+ merges wrong-password + user-not-found
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Try again later.';

      // ── Signup errors ─────────────────────────────────────────────────────
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';

      // ── Shared / format errors ────────────────────────────────────────────
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and retry.';
      case 'operation-not-allowed':
        return 'Sign-in method not enabled. Contact support.';

      default:
        // Fall back to code string check for unexpected wrapped exceptions
        final msg = e.toString();
        if (msg.contains('user-not-found'))
          return 'No account found with this email.';
        if (msg.contains('wrong-password'))
          return 'Incorrect password. Please try again.';
        if (msg.contains('invalid-credential'))
          return 'Email or password is incorrect.';
        if (msg.contains('email-already-in-use'))
          return 'An account already exists with this email.';
        if (msg.contains('weak-password'))
          return 'Password is too weak. Use at least 6 characters.';
        if (msg.contains('invalid-email'))
          return 'Please enter a valid email address.';
        if (msg.contains('too-many-requests'))
          return 'Too many failed attempts. Try again later.';
        if (msg.contains('network-request-failed'))
          return 'No internet connection. Check your network and retry.';
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _firebaseUserSub.cancel();
    _localUserSub.cancel();
    return super.close();
  }
}
