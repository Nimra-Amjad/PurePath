import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/repositories/community_repository.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/widgets/custom_back_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/community/models/community_notification.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Community notifications page
//
// Live inbox of everything that happened to the user's content: likes on
// their posts/comments/replies, new comments on their posts, and replies to
// their comments.
//
//   • Unread items show a highlighted card + green dot; tapping marks them
//     read and opens the post they refer to.
//   • Swipe left to delete a notification.
//   • "Mark all read" appears in the app bar while anything is unread.
// ─────────────────────────────────────────────────────────────────────────────

class CommunityNotificationsPage extends StatelessWidget {
  const CommunityNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.select<UserBloc, String?>((b) => b.state.user?.uid);
    final repository = context.read<CommunityRepository>();

    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: AppBar(
        backgroundColor: kScaffoldColor,
        surfaceTintColor: kScaffoldColor,
        elevation: 0,
        leading: CustomBackButton(onTap: context.pop),
        title: Text(
          'Notifications',
          style: AppTextStyles.bold.copyWith(fontSize: 18, color: kWhiteColor),
        ),
        actions: [
          if (uid != null)
            StreamBuilder<int>(
              stream: repository.watchUnreadNotificationCount(uid),
              builder: (context, snap) {
                final unread = snap.data ?? 0;
                if (unread == 0) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () => repository.markAllNotificationsRead(uid),
                  child: Text(
                    'Mark all read',
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: kLightGreenColor,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: uid == null
          ? const _EmptyState()
          : StreamBuilder<List<CommunityNotification>>(
              stream: repository.watchNotifications(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: kWhiteColor,
                      strokeWidth: 2,
                    ),
                  );
                }

                final notifications = snap.data ?? const [];
                if (notifications.isEmpty) return const _EmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: notifications.length,
                  itemBuilder: (context, i) => _NotificationTile(
                    key: ValueKey(notifications[i].id),
                    notification: notifications[i],
                    uid: uid,
                  ),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification tile — swipe to delete, tap to open the post
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final CommunityNotification notification;
  final String uid;

  const _NotificationTile({
    super.key,
    required this.notification,
    required this.uid,
  });

  Future<void> _open(BuildContext context) async {
    final repository = context.read<CommunityRepository>();

    if (!notification.hasRead) {
      repository.markNotificationRead(
        userId: uid,
        notificationId: notification.id,
      );
    }

    final post = await repository.getPostById(notification.postId);
    if (!context.mounted) return;
    if (post == null) {
      AppSnackBar.error(context, 'This post is no longer available.');
      return;
    }
    AppRoute.postDetail.push(context, extra: post);
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;

    return Dismissible(
      key: ValueKey('dismiss_${n.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => context.read<CommunityRepository>().deleteNotification(
            userId: uid,
            notificationId: n.id,
          ),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: red.withOpacityValue(0.85),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: kWhiteColor,
          size: 22,
        ),
      ),
      child: GestureDetector(
        onTap: () => _open(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: n.hasRead
                ? kContainerColor
                : kLightGreenColor.withOpacityValue(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: n.hasRead
                  ? kPrimaryGreyColor
                  : kLightGreenColor.withOpacityValue(0.45),
              width: 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActorAvatar(notification: n),
              Space.horizontal(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.normal.copyWith(
                          fontSize: 13,
                          height: 1.45,
                          color: kWhiteColor,
                        ),
                        children: [
                          TextSpan(
                            text: n.actorName,
                            style: AppTextStyles.semiBold.copyWith(
                              fontSize: 13,
                              color: kWhiteColor,
                            ),
                          ),
                          TextSpan(text: ' ${n.message}'),
                        ],
                      ),
                    ),
                    if (n.preview.trim().isNotEmpty) ...[
                      Space.vertical(4),
                      Text(
                        '“${n.preview.trim()}”',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.normal.copyWith(
                          fontSize: 12,
                          height: 1.45,
                          color: kSecondaryGreyColor,
                        ),
                      ),
                    ],
                    Space.vertical(5),
                    Text(
                      n.timeAgo,
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 11,
                        color: kLightGreyColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!n.hasRead) ...[
                Space.horizontal(8),
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: const BoxDecoration(
                    color: kLightGreenColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Actor initial in their deterministic color, with a small badge showing
/// what kind of event this is (heart / comment / reply).
class _ActorAvatar extends StatelessWidget {
  final CommunityNotification notification;
  const _ActorAvatar({required this.notification});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: n.actorColor.withOpacityValue(0.15),
            child: Text(
              n.actorInitial,
              style: AppTextStyles.bold.copyWith(
                fontSize: 15,
                color: n.actorColor,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3.5),
              decoration: const BoxDecoration(
                color: kContainerColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                n.icon,
                size: 10,
                color: n.icon == Icons.favorite_rounded
                    ? red
                    : kLightGreenColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔔', style: TextStyle(fontSize: 40)),
            Space.vertical(12),
            Text(
              'No notifications yet',
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 15,
                color: kWhiteColor,
              ),
            ),
            Space.vertical(4),
            Text(
              'Likes, comments and replies on your posts\nwill show up here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.normal.copyWith(
                fontSize: 13,
                height: 1.5,
                color: kSecondaryGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
