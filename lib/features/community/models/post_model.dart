import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Community models
//
// These mirror the Firestore document shapes:
//
//   community/<postId>
//     userId, authorName, authorImgUrl, content, imageUrl,
//     createdAt (Timestamp), likedBy [String], commentCount (int)
//
//   community/<postId>/comments/<commentId>
//     userId, authorName, authorImgUrl, text,
//     createdAt (Timestamp), likedBy [String], replyCount (int)
//
//   community/<postId>/comments/<commentId>/replies/<replyId>
//     userId, authorName, authorImgUrl, text,
//     createdAt (Timestamp), likedBy [String]
//
// Identity fields (initial, color, "you" badge, timeAgo) are derived
// client-side so they can't drift from the source of truth.
// ─────────────────────────────────────────────────────────────────────────────

class PostModel {
  final String id;
  final String userId;
  final String authorName;

  /// Author's handle (e.g. `nimraamjad_5`). Filled in live during author
  /// enrichment, so it stays current and works for older posts too. Null when
  /// the author has no username yet.
  final String? authorUsername;
  final String? authorImgUrl;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final List<String> likedBy;
  final int commentCount;

  const PostModel({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorUsername,
    this.authorImgUrl,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.likedBy = const [],
    this.commentCount = 0,
  });

  // ── Derived helpers ────────────────────────────────────────────────────────

  String get authorInitial =>
      authorName.isNotEmpty ? authorName.trim()[0].toUpperCase() : '?';

  Color get authorColor => avatarColorFor(userId);

  String get timeAgo => timeAgoText(createdAt);

  int get likeCount => likedBy.length;

  bool isOwnedBy(String? uid) => uid != null && uid == userId;

  bool isLikedBy(String? uid) => uid != null && likedBy.contains(uid);
}

class CommentModel {
  final String id;
  final String userId;
  final String authorName;
  final String? authorImgUrl;
  final String text;
  final DateTime createdAt;
  final List<String> likedBy;
  final int replyCount;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorImgUrl,
    required this.text,
    required this.createdAt,
    this.likedBy = const [],
    this.replyCount = 0,
  });

  String get authorInitial =>
      authorName.isNotEmpty ? authorName.trim()[0].toUpperCase() : '?';

  Color get authorColor => avatarColorFor(userId);

  String get timeAgo => timeAgoText(createdAt);

  int get likeCount => likedBy.length;

  bool isLikedBy(String? uid) => uid != null && likedBy.contains(uid);
}

class ReplyModel {
  final String id;
  final String userId;
  final String authorName;
  final String? authorImgUrl;
  final String text;
  final DateTime createdAt;
  final List<String> likedBy;

  const ReplyModel({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorImgUrl,
    required this.text,
    required this.createdAt,
    this.likedBy = const [],
  });

  String get authorInitial =>
      authorName.isNotEmpty ? authorName.trim()[0].toUpperCase() : '?';

  Color get authorColor => avatarColorFor(userId);

  String get timeAgo => timeAgoText(createdAt);

  int get likeCount => likedBy.length;

  bool isLikedBy(String? uid) => uid != null && likedBy.contains(uid);
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared client-side derivations
// ─────────────────────────────────────────────────────────────────────────────

const _avatarPalette = <Color>[
  Color(0xFF6C4DFF), // purple
  Color(0xFFEC407A), // pink
  Color(0xFF1E88E5), // blue
  Color(0xFFAB47BC), // mauve
  Color(0xFF5C6BC0), // indigo
  Color(0xFF26A69A), // mint
  Color(0xFFFB8C00), // orange
  Color(0xFF4CAF50), // green
];

/// Deterministic avatar color from a user id, so the same user always gets
/// the same color across the app without needing a stored field.
Color avatarColorFor(String userId) {
  if (userId.isEmpty) return _avatarPalette.first;
  final idx =
      userId.codeUnits.fold<int>(0, (a, b) => a + b) % _avatarPalette.length;
  return _avatarPalette[idx];
}

/// Compact "5m ago", "2h ago", "3d ago" style relative time string.
String timeAgoText(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 30) return 'Just now';
  if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}
