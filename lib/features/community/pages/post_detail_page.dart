import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/app_dialog.dart';
import 'package:purepath/core/widgets/custom_back_button.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/custom_textfield.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/community/bloc/community_bloc.dart';
import 'package:purepath/features/community/models/post_model.dart';
import 'package:purepath/core/repositories/community_repository.dart';
import 'package:purepath/features/community/widgets/post_card_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Post detail page
//
// Streams comments live from Firestore. New comments and replies are
// persisted via [CommunityRepository]. Likes are toggled via the same.
// ─────────────────────────────────────────────────────────────────────────────

class PostDetailPage extends StatefulWidget {
  final PostModel post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _submittingComment = false;

  // Local mirror of the comments stream. We hold our own list so the UI
  // doesn't get rebuilt from scratch every time the stream re-emits — only
  // newly-added items mount, and existing tiles keep their state thanks to
  // ValueKey(comment.id).
  StreamSubscription<List<CommentModel>>? _commentsSub;
  List<CommentModel>? _comments;
  bool _commentsLoaded = false;

  @override
  void initState() {
    super.initState();
    // Defer subscription to first frame so context.read works.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _commentsSub = context
          .read<CommunityRepository>()
          .watchComments(widget.post.id)
          .listen((comments) {
            if (!mounted) return;
            setState(() {
              _comments = comments;
              _commentsLoaded = true;
            });
          });
    });
  }

  @override
  void dispose() {
    _commentsSub?.cancel();
    _commentCtrl.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _submittingComment) return;

    final bloc = context.read<CommunityBloc>();
    final user = bloc.currentUser;
    if (user == null || user.uid.isEmpty) {
      AppSnackBar.error(context, 'Please sign in to comment.');
      return;
    }

    setState(() => _submittingComment = true);
    try {
      await context.read<CommunityRepository>().addComment(
        postId: widget.post.id,
        userId: user.uid,
        authorName: user.fullName,
        authorImgUrl: user.imgUrl,
        text: text,
      );
      _commentCtrl.clear();
      _commentFocus.unfocus();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Could not post comment.');
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.select<UserBloc, String?>(
      (b) => b.state.user?.uid,
    );

    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: AppBar(
        backgroundColor: kScaffoldColor,
        surfaceTintColor: kScaffoldColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: kBlackColor.withOpacityValue(0.08),
        leading: CustomBackButton(onTap: context.pop),
        title: Text(
          'Post',
          style: AppTextStyles.bold.copyWith(fontSize: 18, color: kWhiteColor),
        ),
      ),

      bottomNavigationBar: _CommentInputBar(
        controller: _commentCtrl,
        focusNode: _commentFocus,
        onSubmit: _submitComment,
        submitting: _submittingComment,
      ),

      body: BlocBuilder<CommunityBloc, CommunityState>(
        // Pull the always-current PostModel from the bloc so likes/counts stay
        // fresh while the user is on this page.
        builder: (context, state) {
          final post = state.posts.firstWhere(
            (p) => p.id == widget.post.id,
            orElse: () => widget.post,
          );

          final comments = _comments ?? const <CommentModel>[];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _FullPost(
                  post: post,
                  isLiked: post.isLikedBy(currentUid),
                  onLikeTap: () => context.read<CommunityBloc>().add(
                    CommunityPostLikeToggled(post.id),
                  ),
                ),
              ),

              // ── Comments header (live count) ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        'Comments',
                        style: AppTextStyles.semiBold.copyWith(
                          fontSize: 16,
                          color: kWhiteColor,
                        ),
                      ),
                      Space.horizontal(8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kContainerColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${comments.length}',
                          style: AppTextStyles.semiBold.copyWith(
                            fontSize: 12,
                            color: kWhiteColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Comments list ────────────────────────────────────────────
              if (!_commentsLoaded)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: kWhiteColor,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              else if (comments.isEmpty)
                const SliverToBoxAdapter(child: _EmptyComments())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final c = comments[i];
                    return _CommentTile(
                      // Stable key → existing tiles keep their state and
                      // don't get torn down when a new comment is inserted.
                      key: ValueKey(c.id),
                      postId: post.id,
                      postOwnerId: post.userId,
                      comment: c,
                      currentUid: currentUid,
                    );
                  }, childCount: comments.length),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full post card
// ─────────────────────────────────────────────────────────────────────────────

class _FullPost extends StatelessWidget {
  final PostModel post;
  final bool isLiked;
  final VoidCallback onLikeTap;

  const _FullPost({
    required this.post,
    required this.isLiked,
    required this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = context.select<UserBloc, String?>(
      (b) => b.state.user?.uid,
    );
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryGreyColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: post.authorColor.withOpacityValue(0.15),
                  child: Text(
                    post.authorInitial,
                    style: AppTextStyles.bold.copyWith(
                      fontSize: 16,
                      color: post.authorColor,
                    ),
                  ),
                ),
                Space.horizontal(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorName,
                              style: AppTextStyles.semiBold.copyWith(
                                fontSize: 15,
                                color: kWhiteColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post.isOwnedBy(currentUid)) ...[
                            Space.horizontal(6),
                            _YouBadge(),
                          ],
                        ],
                      ),
                      Space.vertical(2),
                      Text(
                        post.timeAgo,
                        style: AppTextStyles.normal.copyWith(
                          fontSize: 12,
                          color: kLightGreyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.isOwnedBy(currentUid))
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => PostActionsSheet.show(
                      context,
                      post,
                      // The post no longer exists — leave the detail page.
                      onDeleted: () => context.pop(),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 22,
                        color: kSecondaryGreyColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Text(
              post.content,
              style: AppTextStyles.normal.copyWith(
                fontSize: 15,
                height: 1.65,
                color: kWhiteColor,
              ),
            ),
          ),

          if (post.imageUrl != null) ...[
            Space.vertical(12),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 200,
                        color: kLightGreyColor,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: purple,
                          ),
                        ),
                      ),
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],

          Padding(
            padding: EdgeInsets.fromLTRB(
              14,
              post.imageUrl != null ? 12 : 14,
              14,
              14,
            ),
            child: GestureDetector(
              onTap: onLikeTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: isLiked ? red : kSecondaryGreyColor,
                  ),
                  Space.horizontal(5),
                  Text(
                    '${post.likeCount} likes',
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: isLiked ? red : kSecondaryGreyColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Comment tile — like, expand replies, write a reply
// ─────────────────────────────────────────────────────────────────────────────

class _CommentTile extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final CommentModel comment;
  final String? currentUid;

  const _CommentTile({
    super.key,
    required this.postId,
    required this.postOwnerId,
    required this.comment,
    required this.currentUid,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _showReplies = false;
  bool _showReplyInput = false;
  bool _submittingReply = false;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocus = FocusNode();

  // Local mirror of the replies stream for this comment. Subscribed lazily
  // the first time the user opens the replies — keeps idle comments cheap.
  StreamSubscription<List<ReplyModel>>? _repliesSub;
  List<ReplyModel> _replies = const [];

  String _currentInitial(BuildContext context) {
    final name = context.read<CommunityBloc>().currentUser?.fullName ?? '';
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _ensureRepliesSubscribed() {
    if (_repliesSub != null) return;
    _repliesSub = context
        .read<CommunityRepository>()
        .watchReplies(postId: widget.postId, commentId: widget.comment.id)
        .listen((replies) {
          if (!mounted) return;
          setState(() => _replies = replies);
        });
  }

  @override
  void dispose() {
    _repliesSub?.cancel();
    _replyController.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  void _toggleLike() {
    final user = context.read<CommunityBloc>().currentUser;
    if (user == null || user.uid.isEmpty) return;
    context.read<CommunityRepository>().toggleCommentLike(
      postId: widget.postId,
      commentId: widget.comment.id,
      userId: user.uid,
      userName: user.fullName,
    );
  }

  // The comment author can edit + delete their own comment. The post owner
  // can moderate (delete, but not edit) any other user's comment under
  // their post.
  bool get _isCommentOwner =>
      widget.currentUid != null && widget.comment.userId == widget.currentUid;

  bool get _canModerate =>
      _isCommentOwner ||
      (widget.currentUid != null && widget.postOwnerId == widget.currentUid);

  Future<void> _showActions() {
    return AppBottomSheet.show<void>(
      context,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isCommentOwner) ...[
              ActionTile(
                icon: Icons.edit_outlined,
                label: 'Edit comment',
                color: kWhiteColor,
                onTap: () {
                  AppBottomSheet.hide(context);
                  _editComment();
                },
              ),
              Space.vertical(8),
            ],
            ActionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete comment',
              color: red,
              onTap: () {
                AppBottomSheet.hide(context);
                _deleteComment();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editComment() async {
    final newText = await _EditCommentSheet.show(
      context,
      initialText: widget.comment.text,
    );
    if (newText == null || !mounted) return;

    try {
      await context.read<CommunityRepository>().updateComment(
        postId: widget.postId,
        commentId: widget.comment.id,
        text: newText,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Could not update comment.');
    }
  }

  Future<void> _deleteComment() async {
    final confirmed = await AppDialog.show(
      context,
      icon: Icons.delete_outline_rounded,
      iconColor: red,
      title: 'Delete comment?',
      subtitle:
          'This comment and all its replies will be permanently removed.',
      confirmText: 'Delete',
      confirmColor: red,
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<CommunityRepository>().deleteComment(
        postId: widget.postId,
        commentId: widget.comment.id,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Could not delete comment.');
    }
  }

  Future<void> _submitReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _submittingReply) return;

    final bloc = context.read<CommunityBloc>();
    final user = bloc.currentUser;
    if (user == null || user.uid.isEmpty) {
      AppSnackBar.error(context, 'Please sign in to reply.');
      return;
    }

    setState(() => _submittingReply = true);
    try {
      // Make sure we're subscribed before the new reply lands so the stream
      // emission updates the local list without an extra fetch.
      _ensureRepliesSubscribed();
      await context.read<CommunityRepository>().addReply(
        postId: widget.postId,
        commentId: widget.comment.id,
        userId: user.uid,
        authorName: user.fullName,
        authorImgUrl: user.imgUrl,
        text: text,
      );
      _replyController.clear();
      setState(() {
        _showReplies = true;
        _showReplyInput = false;
      });
      _replyFocus.unfocus();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Could not post reply.');
    } finally {
      if (mounted) setState(() => _submittingReply = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    final isLiked = c.isLikedBy(widget.currentUid);

    // Subscribe to replies as soon as the comment has any (so the count
    // stays live) or when the user expands them.
    if (c.replyCount > 0 || _showReplies) {
      _ensureRepliesSubscribed();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimaryGreyColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Comment body ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: c.authorColor.withOpacityValue(0.15),
                  child: Text(
                    c.authorInitial,
                    style: AppTextStyles.semiBold.copyWith(
                      fontSize: 12,
                      color: c.authorColor,
                    ),
                  ),
                ),
                Space.horizontal(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              c.authorName,
                              style: AppTextStyles.semiBold.copyWith(
                                fontSize: 13,
                                color: kWhiteColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Space.horizontal(10),
                          Text(
                            c.timeAgo,
                            style: AppTextStyles.normal.copyWith(
                              fontSize: 11,
                              color: kSecondaryGreyColor,
                            ),
                          ),
                        ],
                      ),
                      Space.vertical(4),
                      Text(
                        c.text,
                        style: AppTextStyles.normal.copyWith(
                          fontSize: 13,
                          height: 1.5,
                          color: kWhiteColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_canModerate)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showActions,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 8),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: kSecondaryGreyColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Comment actions (like + reply + replies toggle) ────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: isLiked ? red : kSecondaryGreyColor,
                      ),
                      Space.horizontal(4),
                      Text(
                        '${c.likeCount}',
                        style: AppTextStyles.medium.copyWith(
                          fontSize: 12,
                          color: isLiked ? red : kSecondaryGreyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Space.horizontal(16),

                GestureDetector(
                  onTap: () => setState(() {
                    _showReplyInput = !_showReplyInput;
                    if (_showReplyInput) {
                      _showReplies = true;
                      Future.delayed(
                        const Duration(milliseconds: 100),
                        () => _replyFocus.requestFocus(),
                      );
                    }
                  }),
                  child: Text(
                    'Reply',
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 12,
                      color: _showReplyInput
                          ? kLightGreenColor
                          : kSecondaryGreyColor,
                    ),
                  ),
                ),

                if (c.replyCount > 0) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showReplies = !_showReplies),
                    child: Row(
                      children: [
                        Text(
                          _showReplies
                              ? 'Hide replies'
                              : '${c.replyCount} ${c.replyCount == 1 ? 'reply' : 'replies'}',
                          style: AppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: kLightGreenColor,
                          ),
                        ),
                        Space.horizontal(3),
                        Icon(
                          _showReplies
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: kLightGreenColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Replies ────────────────────────────────────────────────────
          if (_showReplies && _replies.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 40, right: 14, bottom: 10),
              child: Column(
                children: _replies
                    .map(
                      (r) => _ReplyTile(
                        // Stable key → existing reply tiles don't rebuild
                        // when a new reply is appended.
                        key: ValueKey(r.id),
                        postId: widget.postId,
                        commentId: c.id,
                        reply: r,
                        currentUid: widget.currentUid,
                      ),
                    )
                    .toList(),
              ),
            ),

          // ── Reply input ────────────────────────────────────────────────
          if (_showReplyInput)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF6C4DFF),
                    child: Text(
                      _currentInitial(context),
                      style: const TextStyle(
                        color: kWhiteColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Space.horizontal(8),
                  Expanded(
                    child: CustomTextField(
                      controller: _replyController,
                      focusNode: _replyFocus,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      hintText: 'Write a reply…',
                      onFieldSubmitted: (_) => _submitReply(),
                      suffix: GestureDetector(
                        onTap: _submittingReply ? null : _submitReply,
                        child: _submittingReply
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: purple,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                size: 18,
                                color: purple,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit comment sheet — prefilled text field, pops with the new text
// ─────────────────────────────────────────────────────────────────────────────

class _EditCommentSheet extends StatefulWidget {
  final String initialText;
  const _EditCommentSheet({required this.initialText});

  /// Opens the sheet and resolves to the edited text, or null when the user
  /// dismissed it (or saved without changing anything).
  static Future<String?> show(
    BuildContext context, {
    required String initialText,
  }) {
    return AppBottomSheet.show<String>(
      context,
      body: _EditCommentSheet(initialText: initialText),
    );
  }

  @override
  State<_EditCommentSheet> createState() => _EditCommentSheetState();
}

class _EditCommentSheetState extends State<_EditCommentSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty || text == widget.initialText) {
      context.pop();
      return;
    }
    context.pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit comment',
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 16,
              color: kWhiteColor,
            ),
          ),
          Space.vertical(12),
          CustomTextField(
            controller: _controller,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            hintText: 'Write a comment…',
          ),
          Space.vertical(16),
          PrimaryButton(text: 'Save', onPressed: _save),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reply tile — indented, with its own like toggle
// ─────────────────────────────────────────────────────────────────────────────

class _ReplyTile extends StatelessWidget {
  final String postId;
  final String commentId;
  final ReplyModel reply;
  final String? currentUid;

  const _ReplyTile({
    super.key,
    required this.postId,
    required this.commentId,
    required this.reply,
    required this.currentUid,
  });

  void _toggleLike(BuildContext context) {
    final user = context.read<CommunityBloc>().currentUser;
    if (user == null || user.uid.isEmpty) return;
    context.read<CommunityRepository>().toggleReplyLike(
      postId: postId,
      commentId: commentId,
      replyId: reply.id,
      userId: user.uid,
      userName: user.fullName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = reply.isLikedBy(currentUid);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 1.5,
            height: 50,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: kLightGreyColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          CircleAvatar(
            radius: 13,
            backgroundColor: reply.authorColor.withOpacityValue(0.15),
            child: Text(
              reply.authorInitial,
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 10,
                color: reply.authorColor,
              ),
            ),
          ),
          Space.horizontal(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        reply.authorName,
                        style: AppTextStyles.semiBold.copyWith(
                          fontSize: 12,
                          color: kWhiteColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Space.horizontal(10),
                    Text(
                      reply.timeAgo,
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 10,
                        color: kSecondaryGreyColor,
                      ),
                    ),
                  ],
                ),
                Space.vertical(3),
                Text(
                  reply.text,
                  style: AppTextStyles.normal.copyWith(
                    fontSize: 12,
                    height: 1.5,
                    color: kWhiteColor,
                  ),
                ),
                Space.vertical(5),
                GestureDetector(
                  onTap: () => _toggleLike(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 13,
                        color: isLiked ? red : kSecondaryGreyColor,
                      ),
                      Space.horizontal(3),
                      Text(
                        '${reply.likeCount}',
                        style: AppTextStyles.medium.copyWith(
                          fontSize: 11,
                          color: isLiked ? red : kSecondaryGreyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky comment input bar (bottomNavigationBar)
// ─────────────────────────────────────────────────────────────────────────────

class _CommentInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final bool submitting;

  const _CommentInputBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.submitting,
  });

  @override
  State<_CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<_CommentInputBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final user = context.read<CommunityBloc>().currentUser;
    final initial = (user?.fullName.isNotEmpty ?? false)
        ? user!.fullName[0].toUpperCase()
        : 'A';

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, (bottom > 0 ? bottom : 24) + 10),
      decoration: BoxDecoration(color: kContainerColor),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: kLightGreyColor,
            child: Text(
              initial,
              style: const TextStyle(
                color: kBlackColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Space.horizontal(10),
          Expanded(
            child: CustomTextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              hintText: 'Add a comment…',
              onTap: () => setState(() {}),
              onFieldSubmitted: (_) => widget.onSubmit(),
              suffix: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: _hasText
                    ? GestureDetector(
                        key: const ValueKey('send'),
                        onTap: widget.submitting ? null : widget.onSubmit,
                        child: widget.submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kWhiteColor,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                size: 20,
                                color: kWhiteColor,
                              ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _YouBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: purple.withOpacityValue(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'You',
        style: AppTextStyles.semiBold.copyWith(fontSize: 10, color: purple),
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Text('💬', style: TextStyle(fontSize: 36)),
          Space.vertical(10),
          Text(
            'No comments yet',
            style: AppTextStyles.medium.copyWith(
              fontSize: 14,
              color: kSecondaryGreyColor,
            ),
          ),
        ],
      ),
    );
  }
}
