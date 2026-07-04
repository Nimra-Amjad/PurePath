import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/app_dialog.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/community/bloc/community_bloc.dart';
import 'package:purepath/features/community/models/post_model.dart';
import 'package:purepath/features/community/pages/create_post_page.dart';
import 'package:purepath/features/community/widgets/author_row_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Post card widget
//
// Pure display: like state and like count come from the [PostModel] itself
// (kept fresh by [CommunityBloc]'s Firestore stream). Tapping the heart
// dispatches [CommunityPostLikeToggled].
// ─────────────────────────────────────────────────────────────────────────────

class PostCard extends StatelessWidget {
  final PostModel post;
  final String? currentUid;

  const PostCard({super.key, required this.post, required this.currentUid});

  void _toggleLike(BuildContext context) {
    context.read<CommunityBloc>().add(CommunityPostLikeToggled(post.id));
  }

  void _openDetail(BuildContext context) {
    AppRoute.postDetail.push(context, extra: post);
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = post.isOwnedBy(currentUid);
    final isLiked = post.isLikedBy(currentUid);

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: kContainerColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimaryGreyColor, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthorRowWidget(post: post, isOwn: isOwn),
                  Space.vertical(10),
                  Text(
                    post.content,
                    style: AppTextStyles.normal.copyWith(
                      fontSize: 14,
                      height: 1.6,
                      color: kWhiteColor,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (post.imageUrl != null) _PostImage(url: post.imageUrl!),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  _LikeButton(
                    isLiked: isLiked,
                    count: post.likeCount,
                    onTap: () => _toggleLike(context),
                  ),
                  Space.horizontal(16),
                  _CommentCount(count: post.commentCount),
                  const Spacer(),
                  Text(
                    'Read more',
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 12,
                      color: kLightGreenColor,
                    ),
                  ),
                  Space.horizontal(2),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: kLightGreenColor,
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
// Owner actions sheet — Edit / Delete
// ─────────────────────────────────────────────────────────────────────────────

class PostActionsSheet extends StatelessWidget {
  final PostModel post;
  // The context that opened the sheet (i.e. the PostCard's). The sheet's own
  // BuildContext is torn down the moment we pop, so we use this longer-lived
  // one to show the follow-up dialog and dispatch the delete event.
  final BuildContext parentContext;
  // Invoked after a confirmed delete — lets the detail page pop itself.
  final VoidCallback? onDeleted;

  const PostActionsSheet._({
    required this.post,
    required this.parentContext,
    this.onDeleted,
  });

  /// Opens the bottom sheet with Edit + Delete actions for the post owner.
  static Future<void> show(
    BuildContext context,
    PostModel post, {
    VoidCallback? onDeleted,
  }) {
    return AppBottomSheet.show<void>(
      context,
      body: PostActionsSheet._(
        post: post,
        parentContext: context,
        onDeleted: onDeleted,
      ),
    );
  }

  Future<void> _onEdit(BuildContext context) async {
    context.pop();
    if (!parentContext.mounted) return;
    await CreatePostSheet.showEdit(parentContext, post);
  }

  Future<void> _onDelete(BuildContext context) async {
    context.pop();
    if (!parentContext.mounted) return;
    final confirmed = await AppDialog.show(
      parentContext,
      icon: Icons.delete_outline_rounded,
      iconColor: red,
      title: 'Delete post?',
      subtitle: 'This post and all its comments will be permanently removed.',
      confirmText: 'Delete',
      confirmColor: red,
    );
    if (confirmed == true && parentContext.mounted) {
      parentContext.read<CommunityBloc>().add(CommunityPostDeleted(post.id));
      onDeleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActionTile(
            icon: Icons.edit_outlined,
            label: 'Edit post',
            color: kWhiteColor,
            onTap: () => _onEdit(context),
          ),
          Space.vertical(8),
          ActionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete post',
            color: red,
            onTap: () => _onDelete(context),
          ),
        ],
      ),
    );
  }
}

/// A single row inside an actions bottom sheet (edit / delete / …). Shared
/// by the post actions sheet and the comment actions sheet.
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kContainerColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              Space.horizontal(12),
              Text(
                label,
                style: AppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
        ),
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
            color: isLiked ? red : kSecondaryGreyColor,
          ),
          Space.horizontal(4),
          Text(
            '$count',
            style: AppTextStyles.medium.copyWith(
              fontSize: 13,
              color: isLiked ? red : kSecondaryGreyColor,
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
          color: kSecondaryGreyColor,
        ),
        Space.horizontal(4),
        Text(
          '$count',
          style: AppTextStyles.medium.copyWith(
            fontSize: 13,
            color: kSecondaryGreyColor,
          ),
        ),
      ],
    );
  }
}
