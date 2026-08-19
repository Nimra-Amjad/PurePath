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

  /// Atomically appends [value] to the array [field] on the user document
  /// (no-op if it's already present). Used for the community block / hide
  /// lists so concurrent writes never clobber each other.
  Future<void> addToArrayField(String uid, String field, String value) async {
    await _firestore.collection(_kUsers).doc(uid).update({
      field: FieldValue.arrayUnion([value]),
    });
  }

  /// Atomically removes [value] from the array [field] on the user document.
  Future<void> removeFromArrayField(
    String uid,
    String field,
    String value,
  ) async {
    await _firestore.collection(_kUsers).doc(uid).update({
      field: FieldValue.arrayRemove([value]),
    });
  }

  /// Whether [username] is already used by an account. Usernames are stored
  /// lowercase, so an exact-match query is effectively case-insensitive.
  /// [excludeUid] lets a user keep their own username (their doc doesn't
  /// count as a conflict).
  Future<bool> isUsernameTaken(String username, {String? excludeUid}) async {
    final snap = await _firestore
        .collection(_kUsers)
        .where('username', isEqualTo: username)
        .limit(2)
        .get();

    return snap.docs.any((doc) => doc.id != excludeUid);
  }

  /// Permanently deletes everything in Firestore that belongs to [uid]:
  /// their `users` doc, every `habits` / `insights` doc they own, and every
  /// community post they authored (with nested comments + replies).
  ///
  /// Comments and replies the user wrote on *other people's* posts are left
  /// in place — walking every post in the database to find them would be
  /// expensive, and they're effectively orphaned (no auth account left to
  /// link back to). Their author name will simply persist as a tombstone.
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

    // ── Community posts (subcollections need explicit cascade) ────────────
    final posts = await _firestore
        .collection('community')
        .where('userId', isEqualTo: uid)
        .get();
    for (final postDoc in posts.docs) {
      final comments = await postDoc.reference.collection('comments').get();
      for (final commentDoc in comments.docs) {
        final replies = await commentDoc.reference.collection('replies').get();
        for (final replyDoc in replies.docs) {
          await replyDoc.reference.delete();
        }
        await commentDoc.reference.delete();
      }
      await postDoc.reference.delete();
    }

    // ── User profile doc (delete last so the field-based queries above
    //    still have an authenticated context to run) ────────────────────────
    await _firestore.collection(_kUsers).doc(uid).delete();
  }
}
