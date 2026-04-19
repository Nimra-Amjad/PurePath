part of 'user_bloc.dart';

@immutable
sealed class UserEvent {}

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

class CheckOnboardingUser extends UserEvent {
  final User? user;
  CheckOnboardingUser(this.user);
}
