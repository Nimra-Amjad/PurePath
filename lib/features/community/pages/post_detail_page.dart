import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/community/models/post_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Post detail page
//
// Full post at top → comments below.
// Each comment supports:
//   • Like / unlike (heart + count)
//   • Expand / collapse replies
//   • Type and submit a new reply (stored locally)
// Each reply also supports like / unlike.
// ─────────────────────────────────────────────────────────────────────────────

class PostDetailPage extends StatefulWidget {
  final PostModel post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late bool _isLiked;
  late int _likeCount;
  late List<CommentModel> _comments;

  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _commentFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _isLiked = false;
    _likeCount = widget.post.likeCount;
    _comments = List.of(widget.post.comments);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  void _toggleLike() => setState(() {
    _isLiked = !_isLiked;
    _likeCount += _isLiked ? 1 : -1;
  });

  void _submitComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(
        0,
        CommentModel(
          id: 'c_new_${DateTime.now().millisecondsSinceEpoch}',
          authorName: 'Ahmad',
          authorInitial: 'A',
          authorColor: const Color(0xFF6C4DFF),
          timeAgo: 'Just now',
          text: text,
          likeCount: 0,
          replies: const [],
        ),
      );
    });
    _commentCtrl.clear();
    _commentFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        surfaceTintColor: kWhiteColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: kBlackColor.withOpacityValue(0.08),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: kBlackColor,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Post', style: AppTextStyles.bold.copyWith(fontSize: 18)),
      ),

      // ── Sticky comment input bar ─────────────────────────────────────────
      bottomNavigationBar: _CommentInputBar(
        controller: _commentCtrl,
        focusNode: _commentFocus,
        onSubmit: _submitComment,
      ),

      body: CustomScrollView(
        slivers: [
          // ── Full post ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _FullPost(
              post: post,
              isLiked: _isLiked,
              likeCount: _likeCount,
              onLikeTap: _toggleLike,
            ),
          ),

          // ── Comments header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Comments',
                    style: AppTextStyles.semiBold.copyWith(fontSize: 16),
                  ),
                  Space.horizontal(8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: purple.withOpacityValue(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_comments.length}',
                      style: AppTextStyles.semiBold.copyWith(
                        fontSize: 12,
                        color: purple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Comments list ────────────────────────────────────────────────
          if (_comments.isEmpty)
            const SliverToBoxAdapter(child: _EmptyComments())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _CommentTile(comment: _comments[i]),
                childCount: _comments.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
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
  final int likeCount;
  final VoidCallback onLikeTap;

  const _FullPost({
    required this.post,
    required this.isLiked,
    required this.likeCount,
    required this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kBlackColor.withOpacityValue(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                          Text(
                            post.authorName,
                            style: AppTextStyles.semiBold.copyWith(
                              fontSize: 15,
                            ),
                          ),
                          if (post.isOwnPost) ...[
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
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content (full, no truncation)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Text(
              post.content,
              style: AppTextStyles.normal.copyWith(
                fontSize: 15,
                height: 1.65,
                color: const Color(0xFF374151),
              ),
            ),
          ),

          // Image
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

          // Actions — likes only (comment count is shown in the section below)
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
                    color: isLiked ? red : textSecondary,
                  ),
                  Space.horizontal(5),
                  Text(
                    '$likeCount likes',
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: isLiked ? red : textSecondary,
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
  final CommentModel comment;
  const _CommentTile({required this.comment});

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  late bool _isLiked;
  late int _likeCount;
  bool _showReplies = false;
  bool _showReplyInput = false;
  late List<ReplyModel> _replies;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _isLiked = false;
    _likeCount = widget.comment.likeCount;
    _replies = List.from(widget.comment.replies);
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  void _toggleLike() => setState(() {
    _isLiked = !_isLiked;
    _likeCount += _isLiked ? 1 : -1;
  });

  void _submitReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _replies.add(
        ReplyModel(
          id: 'r_new_${DateTime.now().millisecondsSinceEpoch}',
          authorName: 'Ahmad',
          authorInitial: 'A',
          authorColor: const Color(0xFF6C4DFF),
          timeAgo: 'Just now',
          text: text,
          likeCount: 0,
        ),
      );
      _showReplies = true;
      _showReplyInput = false;
      _replyController.clear();
    });
    _replyFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: kBlackColor.withOpacityValue(0.04), blurRadius: 6),
        ],
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
                  backgroundColor: widget.comment.authorColor.withOpacityValue(
                    0.15,
                  ),
                  child: Text(
                    widget.comment.authorInitial,
                    style: AppTextStyles.semiBold.copyWith(
                      fontSize: 12,
                      color: widget.comment.authorColor,
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
                          Text(
                            widget.comment.authorName,
                            style: AppTextStyles.semiBold.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            widget.comment.timeAgo,
                            style: AppTextStyles.normal.copyWith(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Space.vertical(4),
                      Text(
                        widget.comment.text,
                        style: AppTextStyles.normal.copyWith(
                          fontSize: 13,
                          height: 1.5,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Comment actions (like + reply) ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Row(
              children: [
                // Like
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        _isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: _isLiked ? red : textSecondary,
                      ),
                      Space.horizontal(4),
                      Text(
                        '$_likeCount',
                        style: AppTextStyles.medium.copyWith(
                          fontSize: 12,
                          color: _isLiked ? red : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Space.horizontal(16),

                // Reply button
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
                      color: _showReplyInput ? purple : textSecondary,
                    ),
                  ),
                ),

                // Show/hide replies toggle
                if (_replies.isNotEmpty) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showReplies = !_showReplies),
                    child: Row(
                      children: [
                        Text(
                          _showReplies
                              ? 'Hide replies'
                              : '${_replies.length} ${_replies.length == 1 ? 'reply' : 'replies'}',
                          style: AppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: purple,
                          ),
                        ),
                        Space.horizontal(3),
                        Icon(
                          _showReplies
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: purple,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Replies list ───────────────────────────────────────────────
          if (_showReplies && _replies.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 40, right: 14, bottom: 10),
              child: Column(
                children: _replies
                    .map((reply) => _ReplyTile(reply: reply))
                    .toList(),
              ),
            ),

          // ── Reply input ────────────────────────────────────────────────
          if (_showReplyInput)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF6C4DFF),
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: kWhiteColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Space.horizontal(8),
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      focusNode: _replyFocus,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTextStyles.normal.copyWith(fontSize: 13),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Write a reply…',
                        hintStyle: AppTextStyles.normal.copyWith(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            size: 18,
                            color: purple,
                          ),
                          onPressed: _submitReply,
                        ),
                      ),
                      onSubmitted: (_) => _submitReply(),
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
// Reply tile — indented, with its own like toggle
// ─────────────────────────────────────────────────────────────────────────────

class _ReplyTile extends StatefulWidget {
  final ReplyModel reply;
  const _ReplyTile({required this.reply});

  @override
  State<_ReplyTile> createState() => _ReplyTileState();
}

class _ReplyTileState extends State<_ReplyTile> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = false;
    _likeCount = widget.reply.likeCount;
  }

  void _toggleLike() => setState(() {
    _isLiked = !_isLiked;
    _likeCount += _isLiked ? 1 : -1;
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indent line
          Container(
            width: 1.5,
            height: 50,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: purple.withOpacityValue(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          CircleAvatar(
            radius: 13,
            backgroundColor: widget.reply.authorColor.withOpacityValue(0.15),
            child: Text(
              widget.reply.authorInitial,
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 10,
                color: widget.reply.authorColor,
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
                    Text(
                      widget.reply.authorName,
                      style: AppTextStyles.semiBold.copyWith(fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      widget.reply.timeAgo,
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 10,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                Space.vertical(3),
                Text(
                  widget.reply.text,
                  style: AppTextStyles.normal.copyWith(
                    fontSize: 12,
                    height: 1.5,
                    color: const Color(0xFF374151),
                  ),
                ),
                Space.vertical(5),
                // Like button
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 13,
                        color: _isLiked ? red : textSecondary,
                      ),
                      Space.horizontal(3),
                      Text(
                        '$_likeCount',
                        style: AppTextStyles.medium.copyWith(
                          fontSize: 11,
                          color: _isLiked ? red : textSecondary,
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

  const _CommentInputBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
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
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, (bottom > 0 ? bottom : 24) + 10),
      decoration: BoxDecoration(
        color: kWhiteColor,
        boxShadow: [
          BoxShadow(
            color: kBlackColor.withOpacityValue(0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        // crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF6C4DFF),
            child: Text(
              'A',
              style: TextStyle(
                color: kWhiteColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Space.horizontal(10),

          // Input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.focusNode.hasFocus
                      ? purple.withOpacityValue(0.4)
                      : border,
                  width: 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTextStyles.normal.copyWith(fontSize: 14),
                      onTap: () => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Add a comment…',
                        hintStyle: AppTextStyles.normal.copyWith(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => widget.onSubmit(),
                    ),
                  ),

                  // Send button — only visible when there's text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: _hasText
                        ? Padding(
                            key: const ValueKey('send'),
                            padding: const EdgeInsets.only(right: 6, bottom: 4),
                            child: IconButton(
                              onPressed: widget.onSubmit,
                              icon: const Icon(
                                Icons.send_rounded,
                                size: 20,
                                color: purple,
                              ),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
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
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
