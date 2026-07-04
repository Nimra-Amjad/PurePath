import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CommunityProvider
//
// The only place that touches Firestore for community data. Owns the schema:
//
//   community/<postId>
//     { userId, content, imageUrl?, createdAt: Timestamp,
//       likedBy: [String], commentCount: int }
//
//   community/<postId>/comments/<commentId>
//     { userId, authorName, authorImgUrl?, text,
//       createdAt: Timestamp, likedBy: [String], replyCount: int }
//
//   community/<postId>/comments/<commentId>/replies/<replyId>
//     { userId, authorName, authorImgUrl?, text,
//       createdAt: Timestamp, likedBy: [String] }
//
// Counters (commentCount, replyCount) are denormalised so the feed and
// comment list can render counts without extra queries. They're maintained
// with FieldValue.increment so concurrent writers don't race.
//
// Works with raw snapshots / maps only — model mapping, caching and
// orchestration live in FirestoreCommunityRepository.
// ─────────────────────────────────────────────────────────────────────────────

/// Result of a like toggle: whether the doc is now liked by the user, plus
/// the doc owner + a content snippet so the repository can build a
/// notification without a second read.
typedef LikeToggleResult = ({bool nowLiked, String ownerId, String preview});

class CommunityProvider {
  static const _kPosts = 'community';
  static const _kComments = 'comments';
  static const _kReplies = 'replies';
  static const _kUsers = 'users';
  static const _kNotifications = 'notifications';

  final FirebaseFirestore _firestore;

  CommunityProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _firestore.collection(_kPosts);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_kUsers);

  CollectionReference<Map<String, dynamic>> _commentsRef(String postId) =>
      _postsRef.doc(postId).collection(_kComments);

  CollectionReference<Map<String, dynamic>> _repliesRef(
    String postId,
    String commentId,
  ) =>
      _commentsRef(postId).doc(commentId).collection(_kReplies);

  CollectionReference<Map<String, dynamic>> _notificationsRef(String uid) =>
      _usersRef.doc(uid).collection(_kNotifications);

  // ── Posts ──────────────────────────────────────────────────────────────────

  /// Live snapshots of the top [limit] posts, newest first.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchTopPosts({
    required int limit,
  }) {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Creates a post document and returns its generated id. Posts only store
  /// the userId — author name and avatar are looked up at read time from
  /// the users collection so a profile rename propagates everywhere.
  Future<String> createPost({
    required String userId,
    required String content,
    String? imageUrl,
  }) async {
    final docRef = _postsRef.doc();
    await docRef.set({
      'userId': userId,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'likedBy': <String>[],
      'commentCount': 0,
    });
    return docRef.id;
  }

  Future<void> updatePost({
    required String postId,
    required String content,
    String? imageUrl,
  }) async {
    await _postsRef.doc(postId).update({
      'content': content,
      'imageUrl': imageUrl,
    });
  }

  /// Cascade delete: comments + replies first, then the post itself.
  Future<void> deletePost(String postId) async {
    final comments = await _commentsRef(postId).get();
    for (final commentDoc in comments.docs) {
      final replies = await _repliesRef(postId, commentDoc.id).get();
      for (final replyDoc in replies.docs) {
        await replyDoc.reference.delete();
      }
      await commentDoc.reference.delete();
    }
    await _postsRef.doc(postId).delete();
  }

  Future<LikeToggleResult> togglePostLike({
    required String postId,
    required String userId,
  }) {
    return _toggleLike(_postsRef.doc(postId), userId, previewField: 'content');
  }

  /// Raw post document, or null when it no longer exists.
  Future<Map<String, dynamic>?> fetchPostDoc(String postId) async {
    final snap = await _postsRef.doc(postId).get();
    return snap.data();
  }

  // ── Comments ───────────────────────────────────────────────────────────────

  /// Live snapshots of a post's comments, newest first.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchComments(String postId) {
    return _commentsRef(postId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Creates a comment and bumps the post's comment counter atomically.
  /// Returns the generated comment id.
  Future<String> createComment({
    required String postId,
    required String userId,
    required String authorName,
    String? authorImgUrl,
    required String text,
  }) async {
    final commentRef = _commentsRef(postId).doc();
    final batch = _firestore.batch();
    batch.set(commentRef, {
      'userId': userId,
      'authorName': authorName,
      'authorImgUrl': authorImgUrl,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'likedBy': <String>[],
      'replyCount': 0,
    });
    batch.update(_postsRef.doc(postId), {
      'commentCount': FieldValue.increment(1),
    });
    await batch.commit();
    return commentRef.id;
  }

  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String text,
  }) async {
    await _commentsRef(postId).doc(commentId).update({'text': text});
  }

  /// Cascade delete: replies go in the same batch as the comment itself, so
  /// the comment can never disappear while orphaned replies survive. The
  /// post's comment counter is decremented in the same batch.
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final replies = await _repliesRef(postId, commentId).get();
    final batch = _firestore.batch();
    for (final replyDoc in replies.docs) {
      batch.delete(replyDoc.reference);
    }
    batch.delete(_commentsRef(postId).doc(commentId));
    batch.update(_postsRef.doc(postId), {
      'commentCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  Future<LikeToggleResult> toggleCommentLike({
    required String postId,
    required String commentId,
    required String userId,
  }) {
    return _toggleLike(
      _commentsRef(postId).doc(commentId),
      userId,
      previewField: 'text',
    );
  }

  /// Raw comment document, or null when it no longer exists.
  Future<Map<String, dynamic>?> fetchCommentDoc(
    String postId,
    String commentId,
  ) async {
    final snap = await _commentsRef(postId).doc(commentId).get();
    return snap.data();
  }

  // ── Replies ────────────────────────────────────────────────────────────────

  /// Live snapshots of a comment's replies, oldest first (chat-style).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchReplies({
    required String postId,
    required String commentId,
  }) {
    return _repliesRef(postId, commentId).orderBy('createdAt').snapshots();
  }

  /// Creates a reply and bumps the comment's reply counter atomically.
  /// Returns the generated reply id.
  Future<String> createReply({
    required String postId,
    required String commentId,
    required String userId,
    required String authorName,
    String? authorImgUrl,
    required String text,
  }) async {
    final replyRef = _repliesRef(postId, commentId).doc();
    final batch = _firestore.batch();
    batch.set(replyRef, {
      'userId': userId,
      'authorName': authorName,
      'authorImgUrl': authorImgUrl,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'likedBy': <String>[],
    });
    batch.update(_commentsRef(postId).doc(commentId), {
      'replyCount': FieldValue.increment(1),
    });
    await batch.commit();
    return replyRef.id;
  }

  Future<LikeToggleResult> toggleReplyLike({
    required String postId,
    required String commentId,
    required String replyId,
    required String userId,
  }) {
    return _toggleLike(
      _repliesRef(postId, commentId).doc(replyId),
      userId,
      previewField: 'text',
    );
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  /// Fetches the raw user documents for [uids], keyed by uid. Batched in
  /// chunks of 30 (the Firestore `whereIn` limit).
  Future<Map<String, Map<String, dynamic>>> fetchUserDocs(
    List<String> uids,
  ) async {
    final out = <String, Map<String, dynamic>>{};
    for (var i = 0; i < uids.length; i += 30) {
      final end = i + 30 > uids.length ? uids.length : i + 30;
      final chunk = uids.sublist(i, end);
      final snap =
          await _usersRef.where(FieldPath.documentId, whereIn: chunk).get();
      for (final doc in snap.docs) {
        out[doc.id] = doc.data();
      }
    }
    return out;
  }

  // ── Notifications ──────────────────────────────────────────────────────────
  //
  //   users/<uid>/notifications/<notificationId>
  //     { actorId, actorName, type, postId, commentId?,
  //       preview, hasRead, createdAt: Timestamp }
  //
  // Stored per-user as a subcollection so the inbox and the unread count are
  // plain single-field queries (no composite index required).

  /// Live snapshots of [uid]'s notifications, newest first.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotifications(String uid) {
    return _notificationsRef(uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
  }

  /// Live snapshots of [uid]'s unread notifications (for the badge count).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchUnreadNotifications(
    String uid,
  ) {
    return _notificationsRef(uid)
        .where('hasRead', isEqualTo: false)
        .snapshots();
  }

  Future<void> createNotification({
    required String recipientId,
    required String actorId,
    required String actorName,
    required String type,
    required String postId,
    String? commentId,
    required String preview,
  }) async {
    await _notificationsRef(recipientId).add({
      'actorId': actorId,
      'actorName': actorName,
      'type': type,
      'postId': postId,
      'commentId': commentId,
      'preview': preview,
      'hasRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markNotificationRead(String uid, String notificationId) async {
    await _notificationsRef(uid).doc(notificationId).update({'hasRead': true});
  }

  Future<void> markAllNotificationsRead(String uid) async {
    final unread =
        await _notificationsRef(uid).where('hasRead', isEqualTo: false).get();
    if (unread.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'hasRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String uid, String notificationId) async {
    await _notificationsRef(uid).doc(notificationId).delete();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  /// Transactionally adds/removes [userId] from a doc's `likedBy` array and
  /// reports the outcome (see [LikeToggleResult]).
  Future<LikeToggleResult> _toggleLike(
    DocumentReference<Map<String, dynamic>> doc,
    String userId, {
    required String previewField,
  }) async {
    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final data = snap.data() ?? const <String, dynamic>{};
      final liked = (data['likedBy'] as List? ?? const [])
          .cast<String>()
          .contains(userId);
      tx.update(doc, {
        'likedBy': liked
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
      });
      return (
        nowLiked: !liked,
        ownerId: data['userId'] as String? ?? '',
        preview: data[previewField] as String? ?? '',
      );
    });
  }
}
