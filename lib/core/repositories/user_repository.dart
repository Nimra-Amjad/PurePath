import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purepath/core/providers/user_firestore_provider.dart';
import 'package:purepath/core/providers/user_provider.dart';
import 'package:purepath/features/auth/model/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserRepository
//
// Business-logic layer for user data:
//
//   UserBloc → UserRepository → UserProvider          (in-memory state)
//                             → UserFirestoreProvider (raw Firestore access)
//
// Owns the optimistic-update policy (update cache first, revert on failure)
// and model mapping. Never touches Firestore directly.
//
// SWAP GUIDE: If you move to a REST API later, only UserFirestoreProvider
// changes.
// ─────────────────────────────────────────────────────────────────────────────

class UserRepository {
  UserRepository({
    required this.userProvider,
    required this.userFirestoreProvider,
  });

  final UserProvider userProvider;
  final UserFirestoreProvider userFirestoreProvider;

  // ── Local state passthrough ───────────────────────────────────────────────

  UserModel? get localUser => userProvider.localUser;
  User? get firebaseUser => userProvider.firebaseUser;

  Stream<UserModel?> get userModelStream => userProvider.userModelStream;
  Stream<User?> get firebaseUserStream => userProvider.firebaseUserStream;

  void updateLocalUser(UserModel? user) => userProvider.updateLocalUser(user);
  void updateFirebaseUser(User? user) => userProvider.updateFirebaseUser(user);

  // ── Firestore-backed operations ───────────────────────────────────────────

  /// Fetch the user document for the currently signed-in Firebase user.
  Future<UserModel?> getUserDocumentByUid() async {
    try {
      final uid = firebaseUser?.uid;
      if (uid == null) return null;

      final data = await userFirestoreProvider.fetchUserDoc(uid);
      if (data == null) return null;
      return UserModel.fromMap(data);
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

      await userFirestoreProvider.updateUserDoc(uid, data);
      return true;
    } catch (e) {
      debugPrint('UserRepository.updateUserDocument error: $e');
      return false;
    }
  }

  /// Whether [username] is already taken by another account. The current
  /// user's own document is excluded so re-confirming their existing username
  /// never reports a false conflict.
  Future<bool> isUsernameTaken(String username) async {
    final uid = firebaseUser?.uid;
    return userFirestoreProvider.isUsernameTaken(
      username.trim(),
      excludeUid: uid,
    );
  }

  /// Permanently deletes everything in Firestore that belongs to the current
  /// user. Must be called while the user is still authenticated; once the
  /// auth account is deleted, security rules typically block follow-up
  /// writes.
  Future<void> deleteAllUserData() async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;
    await userFirestoreProvider.deleteAllUserData(uid);
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
  /// optimistic-update pattern used by [setStreak] / [updateFullName]:
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

  /// Records that the one-time "first habit completed" celebration has been
  /// shown, so it never fires again. Same optimistic pattern as
  /// [setNotificationsEnabled]: patch the local cache first, then Firestore,
  /// reverting on failure.
  Future<void> markFirstCompletionCelebrated() async {
    final current = localUser;
    if (current == null || current.hasCelebratedFirstCompletion) return;

    updateLocalUser(current.copyWith(hasCelebratedFirstCompletion: true));

    final ok = await updateUserDocument({'hasCelebratedFirstCompletion': true});
    if (!ok) {
      updateLocalUser(current); // Revert on failure.
    }
  }

  /// Persists the freshly computed coin balance. The value itself is derived
  /// from the insights data via [HomeRepository.calculateCurrentStreak], so
  /// this method just stores the result and patches the local cache.
  Future<void> setStreak(int streak) async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;

    final current = localUser;
    if (current == null || current.streak == streak) return;

    // Optimistic local update so profile/badges/tier card react instantly.
    updateLocalUser(current.copyWith(streak: streak));

    try {
      await userFirestoreProvider.updateUserDoc(uid, {'streak': streak});
    } catch (e) {
      debugPrint('UserRepository.setStreak error: $e');
      updateLocalUser(current); // Revert on failure.
    }
  }
}
