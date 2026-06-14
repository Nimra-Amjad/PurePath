part of 'user_bloc.dart';

@immutable
sealed class UserEvent {}

// ── Auth ──────────────────────────────────────────────────────────────────────

class LoginRequested extends UserEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
}

class SignupRequested extends UserEvent {
  final String fullName;
  final String email;
  final String password;
  SignupRequested({
    required this.fullName,
    required this.email,
    required this.password,
  });
}

class LogoutRequested extends UserEvent {}

// ── Splash / session restore ──────────────────────────────────────────────────

/// Fired from SplashPage to check whether a Firebase session already exists
/// and load the matching Firestore document.
class LoadUser extends UserEvent {
  final User? firebaseUser;
  LoadUser(this.firebaseUser);
}

// ── Onboarding ────────────────────────────────────────────────────────────────

/// Fired when the user finishes the preference steps. Saves goal +
/// challenge to Firestore and marks `onboardingStatus` as completed.
///
/// The notifications master toggle is owned by [NotificationBloc] —
/// `preferences_page` dispatches that event in parallel with this one.
class SaveOnboardingData extends UserEvent {
  final String goal;
  final String challenge;
  final String activityLevel;

  SaveOnboardingData({
    required this.goal,
    required this.challenge,
    required this.activityLevel,
  });
}

// ── Internal stream sync ──────────────────────────────────────────────────────

class _SyncFirebaseUser extends UserEvent {
  final User? user;
  _SyncFirebaseUser(this.user);
}

class _SyncLocalUser extends UserEvent {
  final UserModel? user;
  _SyncLocalUser(this.user);
}
