part of 'community_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Community status
// ─────────────────────────────────────────────────────────────────────────────

enum CommunityStatus { loading, loaded, error }

// ─────────────────────────────────────────────────────────────────────────────
// Community state
//
// Single immutable state — UI always reads from one place.
// ─────────────────────────────────────────────────────────────────────────────

class CommunityState {
  final CommunityStatus status;
  final List<PostModel> posts;
  final String? errorMessage;

  const CommunityState({
    required this.status,
    this.posts = const [],
    this.errorMessage,
  });

  /// Posts authored by [uid] — drives the "My Posts" tab.
  List<PostModel> myPosts(String? uid) {
    if (uid == null || uid.isEmpty) return const [];
    return posts.where((p) => p.userId == uid).toList();
  }

  CommunityState copyWith({
    CommunityStatus? status,
    List<PostModel>? posts,
    String? errorMessage,
  }) {
    return CommunityState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      errorMessage: errorMessage,
    );
  }
}
