import 'package:purepath/features/community/models/post_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Community repository — abstract interface
//
// CommunityBloc and the UI depend only on this interface. Swapping in a
// different backend (e.g. dummy/in-memory for tests) means implementing
// these methods — nothing in the bloc or UI changes.
// ─────────────────────────────────────────────────────────────────────────────

abstract class CommunityRepository {
  // ── Posts ─────────────────────────────────────────────────────────────────

  /// All posts, newest first.
  Future<List<PostModel>> getAllPosts();

  /// Live stream of all posts, newest first.
  Stream<List<PostModel>> watchAllPosts();

  /// Persists a new post authored by [userId].
  Future<PostModel> addPost({
    required String userId,
    required String authorName,
    String? authorImgUrl,
    required String content,
    String? imageUrl,
  });

  /// Permanently removes a post and all of its comments + replies.
  Future<void> deletePost(String postId);

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
