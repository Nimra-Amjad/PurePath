import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserFirestoreProvider
//
// The only place that touches Firestore for the `users` collection (and the
// cross-collection cleanup when an account is deleted). Works with raw maps
// — model mapping and the in-memory user cache live in UserRepository /
// UserProvider.
// ─────────────────────────────────────────────────────────────────────────────

class UserFirestoreProvider {
  static const _kUsers = 'users';

  final FirebaseFirestore _firestore;

  UserFirestoreProvider({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Raw user document for [uid], or null when it doesn't exist.
  Future<Map<String, dynamic>?> fetchUserDoc(String uid) async {
    final snap = await _firestore.collection(_kUsers).doc(uid).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  /// Patches arbitrary fields on the user document.
  Future<void> updateUserDoc(String uid, Map<String, dynamic> data) async {
    await _firestore.collection(_kUsers).doc(uid).update(data);
  }

  /// Permanently deletes everything in Firestore that belongs to [uid]:
  /// their `users` doc and every `habits` / `insights` doc they own.
  ///
  /// Must be called while the user is still authenticated; once the auth
  /// account is deleted, security rules typically block follow-up writes.
  Future<void> deleteAllUserData(String uid) async {
    // ── Top-level collections owned by uid ────────────────────────────────
    Future<void> deleteOwned(String collection) async {
      final snap = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }

    // Habits live in the `habit/{uid}/habits` subcollection, so they need an
    // explicit subcollection walk rather than a top-level userId query.
    final habitDocs = await _firestore
        .collection('habits')
        .doc(uid)
        .collection('habits')
        .get();
    for (final doc in habitDocs.docs) {
      await doc.reference.delete();
    }

    await deleteOwned('insights');

    // ── User profile doc (delete last so the field-based queries above
    //    still have an authenticated context to run) ────────────────────────
    await _firestore.collection(_kUsers).doc(uid).delete();
  }
}
