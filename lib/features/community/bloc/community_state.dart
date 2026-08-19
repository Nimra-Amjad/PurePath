part of 'community_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Community status
// ─────────────────────────────────────────────────────────────────────────────

enum CommunityStatus { loading, loaded, error }

// ─────────────────────────────────────────────────────────────────────────────
// Community state
//
// Single immutable state — UI always reads from one place.
//
// Pagination fields:
//   • hasMore        — true if the next page exists.
//   • isLoadingMore  — true while a page-after-first fetch is in flight.
// ─────────────────────────────────────────────────────────────────────────────

class CommunityState {
  final CommunityStatus status;
  final List<PostModel> posts;
  final String? errorMessage;
  final bool hasMore;
  final bool isLoadingMore;

  const CommunityState({
    required this.status,
    this.posts = const [],
    this.errorMessage,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  /// Posts authored by [uid] — drives the "My Posts" tab.
  List<PostModel> myPosts(String? uid) {
    if (uid == null || uid.isEmpty) return const [];
    return posts.where((p) => p.userId == uid).toList();
  }

  /// The feed as [viewer] should see it: posts they've hidden and posts by
  /// users they've blocked are filtered out. The two lists are independent —
  /// [UserModel.hiddenPosts] targets individual posts, [UserModel.blockedUsers]
  /// targets authors. Returns [posts] unchanged when the viewer has neither.
  List<PostModel> visiblePosts(UserModel? viewer) {
    if (viewer == null) return posts;
    if (viewer.hiddenPosts.isEmpty && viewer.blockedUsers.isEmpty) return posts;

    final hidden = viewer.hiddenPosts.toSet();
    final blocked = viewer.blockedUsers.toSet();
    return posts
        .where((p) => !hidden.contains(p.id) && !blocked.contains(p.userId))
        .toList();
  }

  CommunityState copyWith({
    CommunityStatus? status,
    List<PostModel>? posts,
    String? errorMessage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return CommunityState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
