import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:purepath/core/repositories/user_repository.dart';
import 'package:purepath/features/auth/model/user_model.dart';
import 'package:purepath/features/community/models/post_model.dart';
import 'package:purepath/core/repositories/community_repository.dart';

part 'community_event.dart';
part 'community_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CommunityBloc
//
// Owns the community feed.
//
// Real-time + paginated. The feed is backed by a live Firestore snapshot
// stream of the top N posts (N = currently-loaded count, grows by 10 each
// time the user scrolls to the bottom). Every change to those posts —
// new post, like, comment count, edit, delete — flows in automatically
// across devices without any pull-to-refresh.
//
// Pagination is just "subscribe with a larger limit":
//   • CommunityStarted              → subscribe with limit = 10.
//   • CommunityLoadMoreRequested    → limit += 10, resubscribe.
//   • CommunityRefreshRequested     → resubscribe at the current limit.
// ─────────────────────────────────────────────────────────────────────────────

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository _repository;
  final UserRepository _userRepository;

  static const _pageSize = 10;

  StreamSubscription<PostsPage>? _feedSub;
  int _currentLimit = _pageSize;

  CommunityBloc({
    required CommunityRepository repository,
    required UserRepository userRepository,
  })  : _repository = repository,
        _userRepository = userRepository,
        super(const CommunityState(status: CommunityStatus.loading)) {
    on<CommunityStarted>(_onStarted);
    on<CommunityRefreshRequested>(_onRefreshRequested);
    on<CommunityLoadMoreRequested>(_onLoadMoreRequested);
    on<CommunityPostCreated>(_onPostCreated);
    on<CommunityPostDeleted>(_onPostDeleted);
    on<CommunityPostUpdated>(_onPostUpdated);
    on<CommunityPostLikeToggled>(_onPostLikeToggled);
    on<_CommunityFeedReceived>(_onFeedReceived);
    on<_CommunityFeedErrored>(_onFeedErrored);
  }

  // ── Event handlers ────────────────────────────────────────────────────────

  void _onStarted(CommunityStarted event, Emitter<CommunityState> emit) {
    // Avoid resubscribing on every page mount if we already have content.
    if (state.status == CommunityStatus.loaded && state.posts.isNotEmpty) {
      return;
    }
    _currentLimit = _pageSize;
    _subscribe();
  }

  void _onRefreshRequested(
    CommunityRefreshRequested event,
    Emitter<CommunityState> emit,
  ) {
    // Drop the author cache so freshly-renamed users show their new name
    // on the very next snapshot (otherwise the cache hides the change
    // until app restart).
    _repository.clearAuthorCache();

    // Re-subscribe at the same limit. Status flips to `loading` so the
    // inline refresh loader at the top of the feed appears until the next
    // snapshot lands.
    emit(state.copyWith(status: CommunityStatus.loading));
    _subscribe();
  }

  void _onLoadMoreRequested(
    CommunityLoadMoreRequested event,
    Emitter<CommunityState> emit,
  ) {
    if (!state.hasMore || state.isLoadingMore) return;
    _currentLimit += _pageSize;
    emit(state.copyWith(isLoadingMore: true));
    _subscribe();
  }

  Future<void> _onPostCreated(
    CommunityPostCreated event,
    Emitter<CommunityState> emit,
  ) async {
    final user = _userRepository.localUser;
    if (user == null || user.uid.isEmpty) return;

    try {
      final created = await _repository.addPost(
        userId: user.uid,
        content: event.content,
        imageUrl: event.imageUrl,
      );
      // Optimistic prepend so the author sees their post instantly. The
      // stream will emit shortly with the canonical doc and replace this.
      final newPost = PostModel(
        id: created.id,
        userId: user.uid,
        authorName: user.fullName,
        authorImgUrl: user.imgUrl,
        content: created.content,
        imageUrl: created.imageUrl,
        createdAt: created.createdAt,
        likedBy: created.likedBy,
        commentCount: created.commentCount,
      );
      emit(state.copyWith(posts: [newPost, ...state.posts]));
    } catch (_) {
      emit(state.copyWith(
        status: CommunityStatus.error,
        errorMessage: 'Could not publish post. Please try again.',
      ));
    }
  }

  Future<void> _onPostDeleted(
    CommunityPostDeleted event,
    Emitter<CommunityState> emit,
  ) async {
    final before = state.posts;
    // Optimistic removal — stream will reconcile if the delete fails.
    emit(state.copyWith(
      posts: before.where((p) => p.id != event.postId).toList(),
    ));
    try {
      await _repository.deletePost(event.postId);
    } catch (_) {
      emit(state.copyWith(posts: before));
    }
  }

  Future<void> _onPostUpdated(
    CommunityPostUpdated event,
    Emitter<CommunityState> emit,
  ) async {
    // Optimistic local update; stream will emit the persisted version.
    final updated = state.posts.map((p) {
      if (p.id != event.postId) return p;
      return PostModel(
        id: p.id,
        userId: p.userId,
        authorName: p.authorName,
        authorImgUrl: p.authorImgUrl,
        content: event.content,
        imageUrl: event.imageUrl,
        createdAt: p.createdAt,
        likedBy: p.likedBy,
        commentCount: p.commentCount,
      );
    }).toList();
    emit(state.copyWith(posts: updated));

    try {
      await _repository.updatePost(
        postId: event.postId,
        content: event.content,
        imageUrl: event.imageUrl,
      );
    } catch (_) {
      // Stream will eventually replay the canonical state — no manual undo.
    }
  }

  Future<void> _onPostLikeToggled(
    CommunityPostLikeToggled event,
    Emitter<CommunityState> emit,
  ) async {
    final user = _userRepository.localUser;
    if (user == null || user.uid.isEmpty) return;

    final uid = user.uid;
    // Optimistic toggle — instant UI feedback before the round-trip.
    final updated = state.posts.map((p) {
      if (p.id != event.postId) return p;
      final liked = p.likedBy.contains(uid);
      final likedBy = List<String>.from(p.likedBy);
      if (liked) {
        likedBy.remove(uid);
      } else {
        likedBy.add(uid);
      }
      return PostModel(
        id: p.id,
        userId: p.userId,
        authorName: p.authorName,
        authorImgUrl: p.authorImgUrl,
        content: p.content,
        imageUrl: p.imageUrl,
        createdAt: p.createdAt,
        likedBy: likedBy,
        commentCount: p.commentCount,
      );
    }).toList();
    emit(state.copyWith(posts: updated));

    try {
      await _repository.togglePostLike(postId: event.postId, userId: uid);
    } catch (_) {
      // Stream emission will reconcile.
    }
  }

  void _onFeedReceived(
    _CommunityFeedReceived event,
    Emitter<CommunityState> emit,
  ) {
    emit(state.copyWith(
      status: CommunityStatus.loaded,
      posts: event.page.posts,
      hasMore: event.page.hasMore,
      isLoadingMore: false,
    ));
  }

  void _onFeedErrored(
    _CommunityFeedErrored event,
    Emitter<CommunityState> emit,
  ) {
    // Only surface the error screen when there's no data to fall back to.
    if (state.posts.isEmpty) {
      emit(state.copyWith(
        status: CommunityStatus.error,
        errorMessage: 'Could not load posts. Please try again.',
      ));
    } else {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _subscribe() {
    _feedSub?.cancel();
    _feedSub = _repository.watchPostsPage(limit: _currentLimit).listen(
          (page) => add(_CommunityFeedReceived(page)),
          onError: (e) => add(_CommunityFeedErrored(e)),
        );
  }

  // Read-only access for pages that need the current user without listening
  // to UserBloc directly (e.g. PostDetailPage).
  UserModel? get currentUser => _userRepository.localUser;

  @override
  Future<void> close() {
    _feedSub?.cancel();
    return super.close();
  }
}
