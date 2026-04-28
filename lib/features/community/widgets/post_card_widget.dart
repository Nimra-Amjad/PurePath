import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/community/models/post_model.dart';
import 'package:purepath/features/community/pages/post_detail_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Post card widget
//
// Displays one [PostModel] in the community feed.
// Like state is managed locally — no BLoC needed for a view-only tab.
// Tapping opens [PostDetailPage].
// ─────────────────────────────────────────────────────────────────────────────

class PostCard extends StatefulWidget {
  final PostModel post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = false;
    _likeCount = widget.post.likeCount;
  }

  void _toggleLike() => setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });

  void _openDetail() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailPage(post: widget.post),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return GestureDetector(
      onTap: _openDetail,
      child: Container(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Author row ─────────────────────────────────────────
                  _AuthorRow(post: post),
                  Space.vertical(10),

                  // ── Post text ──────────────────────────────────────────
                  Text(
                    post.content,
                    style: AppTextStyles.normal.copyWith(
                      fontSize: 14,
                      height: 1.6,
                      color: const Color(0xFF374151),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Image ──────────────────────────────────────────────────
            if (post.imageUrl != null)
              _PostImage(url: post.imageUrl!),

            // ── Actions ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  _LikeButton(
                    isLiked: _isLiked,
                    count: _likeCount,
                    onTap: _toggleLike,
                  ),
                  Space.horizontal(16),
                  _CommentCount(count: post.comments.length),
                  const Spacer(),
                  Text(
                    'Read more',
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 12,
                      color: purple,
                    ),
                  ),
                  Space.horizontal(2),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: purple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Author row
// ─────────────────────────────────────────────────────────────────────────────

class _AuthorRow extends StatelessWidget {
  final PostModel post;
  const _AuthorRow({required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: post.authorColor.withOpacityValue(0.15),
          child: Text(
            post.authorInitial,
            style: AppTextStyles.bold.copyWith(
              fontSize: 15,
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
                    style: AppTextStyles.semiBold.copyWith(fontSize: 14),
                  ),
                  if (post.isOwnPost) ...[
                    Space.horizontal(6),
                    _YouBadge(),
                  ],
                ],
              ),
              Space.vertical(1),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable pieces
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

class _PostImage extends StatelessWidget {
  final String url;
  const _PostImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: Image.network(
        url,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                height: 180,
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
    );
  }
}

class _LikeButton extends StatelessWidget {
  final bool isLiked;
  final int count;
  final VoidCallback onTap;

  const _LikeButton({
    required this.isLiked,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(
            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 19,
            color: isLiked ? red : textSecondary,
          ),
          Space.horizontal(4),
          Text(
            '$count',
            style: AppTextStyles.medium.copyWith(
              fontSize: 13,
              color: isLiked ? red : textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCount extends StatelessWidget {
  final int count;
  const _CommentCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.chat_bubble_outline_rounded,
          size: 17,
          color: textSecondary,
        ),
        Space.horizontal(4),
        Text(
          '$count',
          style: AppTextStyles.medium.copyWith(
            fontSize: 13,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}
