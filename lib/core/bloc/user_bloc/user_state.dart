part of 'user_bloc.dart';

@immutable
abstract class UserState {}

final class UserInitial extends UserState {}

class AuthLoading extends UserState {}

class UserSignedIn extends UserState {
  final UserModel user;
  UserSignedIn(this.user);
}

class UserSignedUp extends UserState {
  final UserModel user;
  UserSignedUp(this.user);
}

class AuthFailure extends UserState {
  final String message;
  AuthFailure(this.message);
}

class UserLoggedOut extends UserState {}
