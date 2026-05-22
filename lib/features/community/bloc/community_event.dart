part of 'community_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Community events
// ─────────────────────────────────────────────────────────────────────────────

sealed class CommunityEvent {}

/// Fired once when the community tab first opens. Loads the first page.
final class CommunityStarted extends CommunityEvent {}

/// Manual pull-to-refresh / retry trigger. Resets the cursor and reloads
/// the first page.
final class CommunityRefreshRequested extends CommunityEvent {}

/// Fired when the feed has been scrolled close to the bottom — loads the
/// next page of posts (no-op if the bloc already has every post).
final class CommunityLoadMoreRequested extends CommunityEvent {}

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

/// Internal: emitted by the feed stream subscription whenever Firestore
/// pushes a fresh snapshot of the current page window.
final class _CommunityFeedReceived extends CommunityEvent {
  final PostsPage page;
  _CommunityFeedReceived(this.page);
}

/// Internal: emitted when the feed stream errors.
final class _CommunityFeedErrored extends CommunityEvent {
  final Object error;
  _CommunityFeedErrored(this.error);
}
