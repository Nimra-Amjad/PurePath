import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purepath/features/community/models/post_model.dart';
import 'package:purepath/features/community/repositories/community_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Firestore community repository
//
// Schema (top-level collection + nested subcollections):
//
//   community/<postId>
//     { userId, authorName, authorImgUrl?, content, imageUrl?,
//       createdAt: Timestamp, likedBy: [String], commentCount: int }
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
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreCommunityRepository implements CommunityRepository {
  static const _kPosts = 'community';
  static const _kComments = 'comments';
  static const _kReplies = 'replies';

  final FirebaseFirestore _firestore;

  FirestoreCommunityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _firestore.collection(_kPosts);

  CollectionReference<Map<String, dynamic>> _commentsRef(String postId) =>
      _postsRef.doc(postId).collection(_kComments);

  CollectionReference<Map<String, dynamic>> _repliesRef(
    String postId,
    String commentId,
  ) =>
      _commentsRef(postId).doc(commentId).collection(_kReplies);

  // ── Posts ──────────────────────────────────────────────────────────────────

  @override
  Future<List<PostModel>> getAllPosts() async {
    final snap = await _postsRef
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snap.docs.map(_postFromDoc).toList();
  }

  @override
  Stream<List<PostModel>> watchAllPosts() {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(_postFromDoc).toList());
  }

  @override
  Future<PostModel> addPost({
    required String userId,
    required String authorName,
    String? authorImgUrl,
    required String content,
    String? imageUrl,
  }) async {
    final docRef = _postsRef.doc();
    final now = DateTime.now();
    await docRef.set({
      'userId': userId,
      'authorName': authorName,
      'authorImgUrl': authorImgUrl,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'likedBy': <String>[],
      'commentCount': 0,
    });
    return PostModel(
      id: docRef.id,
      userId: userId,
      authorName: authorName,
      authorImgUrl: authorImgUrl,
      content: content,
      imageUrl: imageUrl,
      createdAt: now,
      likedBy: const [],
      commentCount: 0,
    );
  }

  @override
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

  @override
  Future<void> deletePost(String postId) async {
    // Cascade: delete comments + replies first, then the post.
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

  @override
  Future<void> togglePostLike({
    required String postId,
    required String userId,
  }) async {
    final doc = _postsRef.doc(postId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final liked = (snap.data()?['likedBy'] as List? ?? const [])
          .cast<String>()
          .contains(userId);
      tx.update(doc, {
        'likedBy': liked
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
      });
    });
  }

  // ── Comments ───────────────────────────────────────────────────────────────

  @override
  Stream<List<CommentModel>> watchComments(String postId) {
    return _commentsRef(postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_commentFromDoc).toList());
  }

  @override
  Future<CommentModel> addComment({
    required String postId,
    required String userId,
    required String authorName,
    String? authorImgUrl,
    required String text,
  }) async {
    final commentRef = _commentsRef(postId).doc();
    final now = DateTime.now();
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
    return CommentModel(
      id: commentRef.id,
      userId: userId,
      authorName: authorName,
      authorImgUrl: authorImgUrl,
      text: text,
      createdAt: now,
    );
  }

  @override
  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    final doc = _commentsRef(postId).doc(commentId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final liked = (snap.data()?['likedBy'] as List? ?? const [])
          .cast<String>()
          .contains(userId);
      tx.update(doc, {
        'likedBy': liked
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
      });
    });
  }

  // ── Replies ────────────────────────────────────────────────────────────────

  @override
  Stream<List<ReplyModel>> watchReplies({
    required String postId,
    required String commentId,
  }) {
    return _repliesRef(postId, commentId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(_replyFromDoc).toList());
  }

  @override
  Future<ReplyModel> addReply({
    required String postId,
    required String commentId,
    required String userId,
    required String authorName,
    String? authorImgUrl,
    required String text,
  }) async {
    final replyRef = _repliesRef(postId, commentId).doc();
    final now = DateTime.now();
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
    return ReplyModel(
      id: replyRef.id,
      userId: userId,
      authorName: authorName,
      authorImgUrl: authorImgUrl,
      text: text,
      createdAt: now,
    );
  }

  @override
  Future<void> toggleReplyLike({
    required String postId,
    required String commentId,
    required String replyId,
    required String userId,
  }) async {
    final doc = _repliesRef(postId, commentId).doc(replyId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final liked = (snap.data()?['likedBy'] as List? ?? const [])
          .cast<String>()
          .contains(userId);
      tx.update(doc, {
        'likedBy': liked
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
      });
    });
  }

  // ── Mappers ────────────────────────────────────────────────────────────────

  static PostModel _postFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return PostModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorImgUrl: data['authorImgUrl'] as String?,
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      createdAt: _readDate(data['createdAt']),
      likedBy:
          (data['likedBy'] as List?)?.cast<String>() ?? const <String>[],
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
    );
  }

  static CommentModel _commentFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return CommentModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorImgUrl: data['authorImgUrl'] as String?,
      text: data['text'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      likedBy:
          (data['likedBy'] as List?)?.cast<String>() ?? const <String>[],
      replyCount: (data['replyCount'] as num?)?.toInt() ?? 0,
    );
  }

  static ReplyModel _replyFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ReplyModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorImgUrl: data['authorImgUrl'] as String?,
      text: data['text'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      likedBy:
          (data['likedBy'] as List?)?.cast<String>() ?? const <String>[],
    );
  }

  /// Reads a Firestore timestamp safely. Server timestamps can be null in the
  /// brief window between the local write and the server ack — fall back to
  /// "now" so the post still renders with a sensible time.
  static DateTime _readDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    return DateTime.now();
  }
}
