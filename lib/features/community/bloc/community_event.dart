part of 'community_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Community events
// ─────────────────────────────────────────────────────────────────────────────

sealed class CommunityEvent {}

/// Fired once when the community tab first opens.
final class CommunityStarted extends CommunityEvent {}

/// Manual pull-to-refresh / retry trigger.
final class CommunityRefreshRequested extends CommunityEvent {}

/// Persists a new post and prepends it to the feed.
final class CommunityPostCreated extends CommunityEvent {
  final String content;
  final String? imageUrl;
  CommunityPostCreated({required this.content, this.imageUrl});
}

/// Removes [postId] from Firestore + the local feed.
final class CommunityPostDeleted extends CommunityEvent {
  final String postId;
  CommunityPostDeleted(this.postId);
}

/// Updates content / image of an existing post the user owns.
final class CommunityPostUpdated extends CommunityEvent {
  final String postId;
  final String content;
  final String? imageUrl;
  CommunityPostUpdated({
    required this.postId,
    required this.content,
    this.imageUrl,
  });
}

/// Toggles whether the current user likes [postId].
final class CommunityPostLikeToggled extends CommunityEvent {
  final String postId;
  CommunityPostLikeToggled(this.postId);
}

/// Internal: fired when the Firestore stream emits a fresh feed.
final class _CommunityFeedReceived extends CommunityEvent {
  final List<PostModel> posts;
  _CommunityFeedReceived(this.posts);
}

/// Internal: fired when the Firestore stream emits an error.
final class _CommunityFeedErrored extends CommunityEvent {
  final Object error;
  _CommunityFeedErrored(this.error);
}
