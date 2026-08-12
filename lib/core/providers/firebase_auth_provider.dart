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
      onboardingStatus: OnboardingStatus.inProgress,
      password: password,
    );

    await firestore.collection('users').doc(user.uid).set(user.toMap());

    return user;
  }

  Future<void> logout() => auth.signOut();

  /// Sends a Firebase password-reset email to [email]. Firebase handles the
  /// reset link and the hosted page where the user picks a new password.
  Future<void> sendPasswordResetEmail(String email) =>
      auth.sendPasswordResetEmail(email: email);

  /// Re-runs the recent-login check that Firebase requires before sensitive
  /// operations (password change, account deletion). Throws a
  /// [FirebaseAuthException] with code `wrong-password` /
  /// `invalid-credential` if [password] is incorrect.
  Future<void> reauthenticate(String password) async {
    final user = auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to do that.',
      );
    }
    final cred =
        EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(cred);
  }

  /// Permanently deletes the current Firebase Auth user. Caller is
  /// responsible for cleaning up Firestore data first — once the auth
  /// account is gone, security rules typically block any further writes.
  Future<void> deleteAccount() async {
    await auth.currentUser?.delete();
  }

  /// Re-authenticates the current user with [currentPassword] and then
  /// updates their Firebase Auth password to [newPassword]. Also patches
  /// the cached `password` field on the user's Firestore doc so it stays
  /// in sync with the rest of the model.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to change your password.',
      );
    }

    // Recent-login required for sensitive operations like updatePassword.
    final cred =
        EmailAuthProvider.credential(email: email, password: currentPassword);
    await user.reauthenticateWithCredential(cred);

    await user.updatePassword(newPassword);

    // Keep the mirrored field on the Firestore user doc in sync.
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'password': newPassword});
  }
}
