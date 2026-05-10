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

  /// Permanently deletes everything in Firestore that belongs to the current
  /// user: their `users` doc, every `habits` doc they own, every per-day
  /// `insights` doc, and every community post they authored (along with the
  /// post's nested comments + replies subcollections).
  ///
  /// Comments and replies the user wrote on *other people's* posts are left
  /// in place — walking every post in the database to find them would be
  /// expensive, and they're effectively orphaned (no auth account left to
  /// link back to). Their author name will simply persist as a tombstone.
  ///
  /// Must be called while the user is still authenticated; once the auth
  /// account is deleted, security rules typically block follow-up writes.
  Future<void> deleteAllUserData() async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;

    final db = FirebaseFirestore.instance;

    // ── Top-level collections owned by uid ────────────────────────────────
    Future<void> deleteOwned(String collection) async {
      final snap =
          await db.collection(collection).where('userId', isEqualTo: uid).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }

    await deleteOwned('habits');
    await deleteOwned('insights');

    // ── Community posts (subcollections need explicit cascade) ────────────
    final posts = await db
        .collection('community')
        .where('userId', isEqualTo: uid)
        .get();
    for (final postDoc in posts.docs) {
      final comments = await postDoc.reference.collection('comments').get();
      for (final commentDoc in comments.docs) {
        final replies =
            await commentDoc.reference.collection('replies').get();
        for (final replyDoc in replies.docs) {
          await replyDoc.reference.delete();
        }
        await commentDoc.reference.delete();
      }
      await postDoc.reference.delete();
    }

    // ── User profile doc (delete last so the field-based queries above
    //    still have an authenticated context to run) ────────────────────────
    await db.collection(_kUsers).doc(uid).delete();
  }

  /// Renames the current user. Updates Firestore + local cache so anything
  /// listening to `UserBloc` (profile header, home greeting, post avatars)
  /// reflects the change immediately.
  Future<bool> updateFullName(String fullName) async {
    final ok = await updateUserDocument({'fullName': fullName});
    final current = localUser;
    if (ok && current != null) {
      updateLocalUser(current.copyWith(fullName: fullName));
    }
    return ok;
  }

  /// Flips the user's "notifications enabled" master switch. Mirrors the
  /// optimistic-update pattern used by [setCoins] / [updateFullName]:
  ///   1. Update the local cache so any listener (profile tab, notification
  ///      bloc) reacts instantly.
  ///   2. Patch Firestore.
  ///   3. Revert on failure so the UI doesn't lie.
  Future<bool> setNotificationsEnabled(bool enabled) async {
    final current = localUser;
    if (current == null) return false;
    if (current.notificationsEnabled == enabled) return true;

    updateLocalUser(current.copyWith(notificationsEnabled: enabled));

    final ok = await updateUserDocument({'notificationsEnabled': enabled});
    if (!ok) {
      updateLocalUser(current);
    }
    return ok;
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
