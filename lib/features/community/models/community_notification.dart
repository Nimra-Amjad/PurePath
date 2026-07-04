import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:purepath/features/community/models/post_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CommunityNotification
//
// Mirrors a document in `users/<uid>/notifications/<notificationId>`:
//
//   { actorId, actorName, type, postId, commentId?,
//     preview, hasRead, createdAt: Timestamp }
//
// One doc per event: someone liked your post/comment/reply, commented on
// your post, or replied to your comment. `preview` is a snippet of the
// content the event refers to, so the list is readable even if the content
// is later edited or deleted.
// ─────────────────────────────────────────────────────────────────────────────

enum CommunityNotificationType {
  postLike,
  commentLike,
  replyLike,
  comment,
  reply;

  static CommunityNotificationType fromName(String? raw) {
    return CommunityNotificationType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => CommunityNotificationType.postLike,
    );
  }
}

class CommunityNotification {
  final String id;
  final String actorId;
  final String actorName;
  final CommunityNotificationType type;
  final String postId;
  final String? commentId;
  final String preview;
  final bool hasRead;
  final DateTime createdAt;

  const CommunityNotification({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.type,
    required this.postId,
    this.commentId,
    required this.preview,
    required this.hasRead,
    required this.createdAt,
  });

  factory CommunityNotification.fromMap(String id, Map<String, dynamic> map) {
    final rawDate = map['createdAt'];
    return CommunityNotification(
      id: id,
      actorId: map['actorId'] as String? ?? '',
      actorName: map['actorName'] as String? ?? '',
      type: CommunityNotificationType.fromName(map['type'] as String?),
      postId: map['postId'] as String? ?? '',
      commentId: map['commentId'] as String?,
      preview: map['preview'] as String? ?? '',
      hasRead: map['hasRead'] as bool? ?? false,
      createdAt: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
    );
  }

  // ── Derived helpers (same conventions as the post/comment models) ─────────

  String get actorInitial =>
      actorName.isNotEmpty ? actorName.trim()[0].toUpperCase() : '?';

  Color get actorColor => avatarColorFor(actorId);

  String get timeAgo => timeAgoText(createdAt);

  /// The action sentence rendered after the actor's name.
  String get message => switch (type) {
        CommunityNotificationType.postLike => 'liked your post',
        CommunityNotificationType.commentLike => 'liked your comment',
        CommunityNotificationType.replyLike => 'liked your reply',
        CommunityNotificationType.comment => 'commented on your post',
        CommunityNotificationType.reply => 'replied to your comment',
      };

  IconData get icon => switch (type) {
        CommunityNotificationType.postLike ||
        CommunityNotificationType.commentLike ||
        CommunityNotificationType.replyLike =>
          Icons.favorite_rounded,
        CommunityNotificationType.comment => Icons.chat_bubble_rounded,
        CommunityNotificationType.reply => Icons.reply_rounded,
      };
}
