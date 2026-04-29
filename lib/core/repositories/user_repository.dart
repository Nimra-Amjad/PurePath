import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purepath/core/providers/user_provider.dart';
import 'package:purepath/features/auth/model/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserRepository
//
// The only place that talks to Firestore for user data.
// Delegates in-memory state to UserProvider.
//
// Pattern mirrors MacroPath's UserRepository:
//   UserProvider ← UserRepository ← UserBloc
//
// SWAP GUIDE: If you move to a REST API later, only this file changes.
// ─────────────────────────────────────────────────────────────────────────────

class UserRepository {
  UserRepository({required this.userProvider});

  final UserProvider userProvider;

  static const _kUsers = 'users';

  // ── Local state passthrough ───────────────────────────────────────────────

  UserModel? get localUser => userProvider.localUser;
  User? get firebaseUser => userProvider.firebaseUser;

  Stream<UserModel?> get userModelStream => userProvider.userModelStream;
  Stream<User?> get firebaseUserStream => userProvider.firebaseUserStream;

  void updateLocalUser(UserModel? user) => userProvider.updateLocalUser(user);
  void updateFirebaseUser(User? user) => userProvider.updateFirebaseUser(user);

  // ── Firestore ─────────────────────────────────────────────────────────────

  /// Fetch the user document for the currently signed-in Firebase user.
  Future<UserModel?> getUserDocumentByUid() async {
    try {
      final uid = firebaseUser?.uid;
      if (uid == null) return null;

      final snap = await FirebaseFirestore.instance
          .collection(_kUsers)
          .doc(uid)
          .get();

      if (!snap.exists || snap.data() == null) return null;
      return UserModel.fromMap(snap.data()!);
    } catch (e) {
      debugPrint('UserRepository.getUserDocumentByUid error: $e');
      return null;
    }
  }

  /// Patch arbitrary fields on the current user's Firestore document.
  Future<bool> updateUserDocument(Map<String, dynamic> data) async {
    try {
      final uid = firebaseUser?.uid;
      if (uid == null) return false;

      await FirebaseFirestore.instance
          .collection(_kUsers)
          .doc(uid)
          .update(data);
      return true;
    } catch (e) {
      debugPrint('UserRepository.updateUserDocument error: $e');
      return false;
    }
  }
}
