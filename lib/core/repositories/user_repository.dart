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

  /// Persists the freshly computed day-streak. The streak itself is derived
  /// from the insights data via [HomeRepository.calculateCurrentStreak], so
  /// this method just stores the result and patches the local cache.
  ///
  /// Doing it this way means backfilling a previously-missed day correctly
  /// extends (or repairs) the streak — the recompute is the source of truth.
  Future<void> setCoins(int coins) async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;

    final current = localUser;
    if (current == null || current.coins == coins) return;

    // Optimistic local update so profile/badges/tier card react instantly.
    updateLocalUser(current.copyWith(coins: coins));

    try {
      await FirebaseFirestore.instance
          .collection(_kUsers)
          .doc(uid)
          .update({'coins': coins});
    } catch (e) {
      debugPrint('UserRepository.setCoins error: $e');
      updateLocalUser(current); // Revert on failure.
    }
  }
}
