part of 'user_bloc.dart';

@immutable
abstract class UserState {
  final UserModel? user;
  final User? firebaseUser;

  const UserState({this.user, this.firebaseUser});
}

// ── Initial / empty ───────────────────────────────────────────────────────────

final class UserInitial extends UserState {
  const UserInitial() : super(user: null, firebaseUser: null);
}

// ── Loading ───────────────────────────────────────────────────────────────────

class AuthLoading extends UserState {
  const AuthLoading({super.user, super.firebaseUser});
}

// ── Loaded base — carries user data; subclassed for each outcome ──────────────

class UserLoaded extends UserState {
  const UserLoaded({required UserModel super.user, super.firebaseUser});

  UserLoaded copyWith({UserModel? user, User? firebaseUser}) => UserLoaded(
        user: user ?? this.user!,
        firebaseUser: firebaseUser ?? this.firebaseUser,
      );
}

// ── Auth outcomes ─────────────────────────────────────────────────────────────

/// User successfully signed in (existing account).
class UserSignedIn extends UserLoaded {
  const UserSignedIn({required super.user, super.firebaseUser});
}

/// New account created — onboarding not yet done.
class UserSignedUp extends UserLoaded {
  const UserSignedUp({required super.user, super.firebaseUser});
}

/// Fired from SplashPage when a previous session is restored and onboarding
/// is already complete — navigate straight to home.
class UserSessionRestored extends UserLoaded {
  const UserSessionRestored({required super.user, super.firebaseUser});
}

/// Firebase user found but onboarding was never finished — send back to preferences.
class UserOnboardingIncomplete extends UserLoaded {
  const UserOnboardingIncomplete({required super.user, super.firebaseUser});
}

// ── Onboarding ────────────────────────────────────────────────────────────────

/// Onboarding data saved successfully — navigate to welcome screen.
class OnboardingCompleted extends UserLoaded {
  const OnboardingCompleted({required super.user, super.firebaseUser});
}

// ── Errors / session end ──────────────────────────────────────────────────────

class AuthFailure extends UserState {
  final String message;
  const AuthFailure(this.message) : super(user: null, firebaseUser: null);
}

class UserNotFound extends UserState {
  const UserNotFound() : super(user: null, firebaseUser: null);
}

class UserLoggedOut extends UserState {
  const UserLoggedOut() : super(user: null, firebaseUser: null);
}
