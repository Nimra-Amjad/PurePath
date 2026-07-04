import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purepath/features/community/models/post_model.dart';
import 'package:purepath/core/providers/community_provider.dart';
import 'package:purepath/core/repositories/community_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Firestore community repository
//
// Business-logic layer between CommunityBloc/UI and CommunityProvider:
//
//   CommunityBloc / pages → FirestoreCommunityRepository → CommunityProvider
//
// The provider owns all raw Firestore access + the document schema. This
// class owns everything on top of that: mapping raw docs to models,
// pagination (hasMore), author enrichment and its session cache, and the
// optimistic models returned to callers after a write.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreCommunityRepository implements CommunityRepository {
  final CommunityProvider _provider;

  FirestoreCommunityRepository({required CommunityProvider provider})
      : _provider = provider;

  // Session-level cache of user docs (uid → data) so successive feed
  // snapshots only fetch authors we haven't seen yet. Reset implicitly on
  // app restart; renames within a session may stay stale until then.
  final Map<String, Map<String, dynamic>> _userCache = {};

  // ── Posts ──────────────────────────────────────────────────────────────────

  @override
  void clearAuthorCache() => _userCache.clear();

  @override
  Stream<PostsPage> watchPostsPage({required int limit}) {
    // Fetch limit + 1 to detect whether more pages exist without an extra
    // round-trip.
    return _provider.watchTopPosts(limit: limit + 1).asyncMap((snap) async {
      final hasMore = snap.docs.length > limit;
      final pageDocs = hasMore ? snap.docs.take(limit).toList() : snap.docs;
      final rawPosts = pageDocs.map(_postFromDoc).toList();
      final enriched = await _enrichWithAuthors(rawPosts);
      return PostsPage(posts: enriched, hasMore: hasMore);
    });
  }

  @override
  Future<PostModel> addPost({
    required String userId,
    required String content,
    String? imageUrl,
  }) async {
    final id = await _provider.createPost(
      userId: userId,
      content: content,
      imageUrl: imageUrl,
    );
    return PostModel(
      id: id,
      userId: userId,
      authorName: '',
      authorImgUrl: null,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      likedBy: const [],
      commentCount: 0,
    );
  }

  @override
  Future<void> updatePost({
    required String postId,
    required String content,
    String? imageUrl,
  }) {
    return _provider.updatePost(
      postId: postId,
      content: content,
      imageUrl: imageUrl,
    );
  }

  @override
  Future<void> deletePost(String postId) => _provider.deletePost(postId);

  @override
  Future<void> togglePostLike({
    required String postId,
    required String userId,
  }) {
    return _provider.togglePostLike(postId: postId, userId: userId);
  }

  // ── Comments ───────────────────────────────────────────────────────────────

  @override
  Stream<List<CommentModel>> watchComments(String postId) {
    return _provider
        .watchComments(postId)
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
    final id = await _provider.createComment(
      postId: postId,
      userId: userId,
      authorName: authorName,
      authorImgUrl: authorImgUrl,
      text: text,
    );
    return CommentModel(
      id: id,
      userId: userId,
      authorName: authorName,
      authorImgUrl: authorImgUrl,
      text: text,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String text,
  }) {
    return _provider.updateComment(
      postId: postId,
      commentId: commentId,
      text: text,
    );
  }

  @override
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) {
    return _provider.deleteComment(postId: postId, commentId: commentId);
  }

  @override
  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required String userId,
  }) {
    return _provider.toggleCommentLike(
      postId: postId,
      commentId: commentId,
      userId: userId,
    );
  }

  // ── Replies ────────────────────────────────────────────────────────────────

  @override
  Stream<List<ReplyModel>> watchReplies({
    required String postId,
    required String commentId,
  }) {
    return _provider
        .watchReplies(postId: postId, commentId: commentId)
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
    final id = await _provider.createReply(
      postId: postId,
      commentId: commentId,
      userId: userId,
      authorName: authorName,
      authorImgUrl: authorImgUrl,
      text: text,
    );
    return ReplyModel(
      id: id,
      userId: userId,
      authorName: authorName,
      authorImgUrl: authorImgUrl,
      text: text,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> toggleReplyLike({
    required String postId,
    required String commentId,
    required String replyId,
    required String userId,
  }) {
    return _provider.toggleReplyLike(
      postId: postId,
      commentId: commentId,
      replyId: replyId,
      userId: userId,
    );
  }

  // ── Author enrichment ─────────────────────────────────────────────────────

  /// Looks up the current `fullName` + `imgUrl` for every unique author id
  /// in [posts] and returns a new list with that data filled in. Uses an
  /// in-memory cache so re-emissions of the feed stream (likes, comment
  /// counts, edits) don't re-fetch authors we already have.
  Future<List<PostModel>> _enrichWithAuthors(List<PostModel> posts) async {
    if (posts.isEmpty) return posts;

    final uids = posts.map((p) => p.userId).toSet().toList();

    // Only fetch uids we haven't seen yet this session.
    final missing = uids.where((u) => !_userCache.containsKey(u)).toList();
    if (missing.isNotEmpty) {
      _userCache.addAll(await _provider.fetchUserDocs(missing));
    }

    return posts.map((p) {
      final u = _userCache[p.userId];
      if (u == null) return p;
      return PostModel(
        id: p.id,
        userId: p.userId,
        authorName: (u['fullName'] as String?) ?? '',
        authorImgUrl: u['imgUrl'] as String?,
        content: p.content,
        imageUrl: p.imageUrl,
        createdAt: p.createdAt,
        likedBy: p.likedBy,
        commentCount: p.commentCount,
      );
    }).toList();
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
