import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:purepath/core/repositories/user_repository.dart';
import 'package:purepath/features/auth/model/user_model.dart';
import 'package:purepath/features/community/models/post_model.dart';
import 'package:purepath/features/community/repositories/community_repository.dart';

part 'community_event.dart';
part 'community_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CommunityBloc
//
// Owns the feed: subscribes to a live Firestore stream so any post created on
// any device shows up immediately, and exposes mutation events (create,
// delete, like) that route through [CommunityRepository].
//
// Author identity is pulled from [UserRepository.localUser] so callers don't
// have to hand the bloc a UserModel for every event.
// ─────────────────────────────────────────────────────────────────────────────

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository _repository;
  final UserRepository _userRepository;

  StreamSubscription<List<PostModel>>? _feedSub;

  CommunityBloc({
    required CommunityRepository repository,
    required UserRepository userRepository,
  })  : _repository = repository,
        _userRepository = userRepository,
        super(const CommunityState(status: CommunityStatus.loading)) {
    on<CommunityStarted>(_onStarted);
    on<CommunityRefreshRequested>(_onRefreshRequested);
    on<CommunityPostCreated>(_onPostCreated);
    on<CommunityPostDeleted>(_onPostDeleted);
    on<CommunityPostLikeToggled>(_onPostLikeToggled);
    on<_CommunityFeedReceived>(_onFeedReceived);
    on<_CommunityFeedErrored>(_onFeedErrored);
  }

  // ── Event handlers ────────────────────────────────────────────────────────

  void _onStarted(CommunityStarted event, Emitter<CommunityState> emit) {
    _subscribeToFeed();
  }

  void _onRefreshRequested(
    CommunityRefreshRequested event,
    Emitter<CommunityState> emit,
  ) {
    emit(state.copyWith(status: CommunityStatus.loading));
    _subscribeToFeed();
  }

  Future<void> _onPostCreated(
    CommunityPostCreated event,
    Emitter<CommunityState> emit,
  ) async {
    final user = _userRepository.localUser;
    if (user == null || user.uid.isEmpty) return;

    try {
      await _repository.addPost(
        userId: user.uid,
        authorName: user.fullName,
        authorImgUrl: user.imgUrl,
        content: event.content,
        imageUrl: event.imageUrl,
      );
      // Stream subscription will refresh the feed automatically.
    } catch (e) {
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
    try {
      // Optimistic removal — stream will reconcile if the delete fails.
      emit(state.copyWith(
        posts: state.posts.where((p) => p.id != event.postId).toList(),
      ));
      await _repository.deletePost(event.postId);
    } catch (_) {
      // Resync on failure.
      _subscribeToFeed();
    }
  }

  Future<void> _onPostLikeToggled(
    CommunityPostLikeToggled event,
    Emitter<CommunityState> emit,
  ) async {
    final user = _userRepository.localUser;
    if (user == null || user.uid.isEmpty) return;

    final uid = user.uid;
    // Optimistic toggle — instant UI feedback.
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
      // Stream will rectify.
    }
  }

  void _onFeedReceived(
    _CommunityFeedReceived event,
    Emitter<CommunityState> emit,
  ) {
    emit(state.copyWith(
      status: CommunityStatus.loaded,
      posts: event.posts,
    ));
  }

  void _onFeedErrored(
    _CommunityFeedErrored event,
    Emitter<CommunityState> emit,
  ) {
    emit(state.copyWith(
      status: CommunityStatus.error,
      errorMessage: 'Could not load posts. Please try again.',
    ));
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _subscribeToFeed() {
    _feedSub?.cancel();
    _feedSub = _repository.watchAllPosts().listen(
          (posts) => add(_CommunityFeedReceived(posts)),
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
