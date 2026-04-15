import 'package:firebase_auth/firebase_auth.dart';
import 'package:purepath/core/providers/firebase_auth_provider.dart';
import 'package:purepath/features/auth/model/user_model.dart';

class FirebaseAuthRepository {
  FirebaseAuthRepository({required this.firebaseAuthProvider});

  final FirebaseAuthProvider firebaseAuthProvider;

  User? get firebaseUser => firebaseAuthProvider.currentUser;
  Stream<User?> get userChangesStream => firebaseAuthProvider.userChangesStream;

  Future<UserModel> login({required String email, required String password}) =>
      firebaseAuthProvider.login(email: email, password: password);

  Future<UserModel> signup({
    required String fullName,
    required String email,
    required String password,
  }) => firebaseAuthProvider.signup(
    fullName: fullName,
    email: email,
    password: password,
  );

  Future<void> logout() => firebaseAuthProvider.logout();
}
