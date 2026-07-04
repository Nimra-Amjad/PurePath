import 'package:purepath/features/community/models/post_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Community repository — abstract interface
//
// CommunityBloc and the UI depend only on this interface. Swapping in a
// different backend (e.g. dummy/in-memory for tests) means implementing
// these methods — nothing in the bloc or UI changes.
// ─────────────────────────────────────────────────────────────────────────────

/// One page of posts plus a flag telling the caller whether more exist.
class PostsPage {
  final List<PostModel> posts;
  final bool hasMore;
  const PostsPage({required this.posts, required this.hasMore});
}

abstract class CommunityRepository {
  // ── Posts ─────────────────────────────────────────────────────────────────

  /// Live stream of the top [limit] posts (newest first). Emits whenever
  /// any of those posts change — likes, comment count, edits — and whenever
  /// a new top post is added or one of the loaded ones is deleted. Pagination
  /// is done by re-calling with a larger limit. Author name + avatar are
  /// enriched per emission from the `users` collection so a profile rename
  /// propagates everywhere on the next snapshot.
  Stream<PostsPage> watchPostsPage({required int limit});

  /// Clears any in-memory cache the repository keeps for author display
  /// data. Called before a manual refresh so freshly-renamed users show
  /// their new name on the very next snapshot (without an app restart).
  void clearAuthorCache();

  /// Persists a new post authored by [userId]. The post document only
  /// stores the user id — name + avatar are looked up on read time so a
  /// rename in the user's profile propagates everywhere.
  Future<PostModel> addPost({
    required String userId,
    required String content,
    String? imageUrl,
  });

  /// Permanently removes a post and all of its comments + replies.
  Future<void> deletePost(String postId);

  /// Updates the content + optional image of an existing post. Other fields
  /// (author, likes, createdAt) are left untouched.
  Future<void> updatePost({
    required String postId,
    required String content,
    String? imageUrl,
  });

  /// Toggles whether [userId] likes [postId]: idempotent on the user's behalf.
  Future<void> togglePostLike({
    required String postId,
    required String userId,
  });

  // ── Comments ──────────────────────────────────────────────────────────────

  /// Live stream of comments for a post, newest first.
  Stream<List<CommentModel>> watchComments(String postId);

  Future<CommentModel> addComment({
    required String postId,
    required String userId,
    required String authorName,
    String? authorImgUrl,
    required String text,
  });

  /// Updates the text of an existing comment. Only offered to the comment
  /// author in the UI; other fields (author, likes, createdAt) are untouched.
  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String text,
  });

  /// Permanently removes a comment and all of its replies, and decrements
  /// the parent post's denormalised comment counter.
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  });

  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required String userId,
  });

  // ── Replies ───────────────────────────────────────────────────────────────

  /// Live stream of replies for a comment, oldest first (chat-style).
  Stream<List<ReplyModel>> watchReplies({
    required String postId,
    required String commentId,
  });

  Future<ReplyModel> addReply({
    required String postId,
    required String commentId,
    required String userId,
    required String authorName,
    String? authorImgUrl,
    required String text,
  });

  Future<void> toggleReplyLike({
    required String postId,
    required String commentId,
    required String replyId,
    required String userId,
  });
}
