import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purepath/core/enums/onboarding_enums.dart';
import 'package:purepath/features/auth/model/user_model.dart';

class FirebaseAuthProvider {
  FirebaseAuthProvider({required this.auth, required this.firestore});

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  User? get currentUser => auth.currentUser;
  Stream<User?> get userChangesStream => auth.userChanges();

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final doc = await firestore
        .collection('users')
        .doc(credential.user!.uid)
        .get();

    return UserModel.fromMap(doc.data()!);
  }

  Future<UserModel> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = UserModel(
      uid: credential.user!.uid,
      email: email,
      fullName: fullName,
      onboardingStatus: OnboardingStatus.notStarted,
      password: password,
    );

    await firestore.collection('users').doc(user.uid).set(user.toMap());

    return user;
  }

  Future<void> logout() => auth.signOut();
}
