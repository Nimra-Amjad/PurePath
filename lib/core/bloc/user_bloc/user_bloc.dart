import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:purepath/core/repositories/firebase_auth_repository.dart';
import 'package:purepath/features/auth/model/user_model.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final FirebaseAuthRepository firebaseAuthRepository;

  UserBloc({required this.firebaseAuthRepository}) : super(UserInitial()) {
    on<LoginRequested>(_loginRequested);
    on<SignupRequested>(_signupRequested);
    on<LogoutRequested>(_logoutRequested);
  }

  Future<void> _loginRequested(
    LoginRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await firebaseAuthRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(UserSignedIn(user));
    } catch (e) {
      emit(AuthFailure(_mapError(e)));
    }
  }

  Future<void> _signupRequested(
    SignupRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await firebaseAuthRepository.signup(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
      );
      emit(UserSignedUp(user));
    } catch (e) {
      emit(AuthFailure(_mapError(e)));
    }
  }

  Future<void> _logoutRequested(
    LogoutRequested event,
    Emitter<UserState> emit,
  ) async {
    await firebaseAuthRepository.logout();
    emit(UserLoggedOut());
  }

  String _mapError(Object e) {
    final msg = e.toString();
    if (msg.contains('user-not-found')) return 'No user found with this email.';
    if (msg.contains('wrong-password')) return 'Incorrect password.';
    if (msg.contains('email-already-in-use'))
      return 'Email already registered.';
    if (msg.contains('weak-password')) return 'Password is too weak.';
    return 'Something went wrong. Please try again.';
  }
}
