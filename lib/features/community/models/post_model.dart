import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Community models
// ─────────────────────────────────────────────────────────────────────────────

class ReplyModel {
  final String id;
  final String authorName;
  final String authorInitial;
  final Color authorColor;
  final String timeAgo;
  final String text;
  final int likeCount;

  const ReplyModel({
    required this.id,
    required this.authorName,
    required this.authorInitial,
    required this.authorColor,
    required this.timeAgo,
    required this.text,
    this.likeCount = 0,
  });
}

class CommentModel {
  final String id;
  final String authorName;
  final String authorInitial;
  final Color authorColor;
  final String timeAgo;
  final String text;
  final int likeCount;
  final List<ReplyModel> replies;

  const CommentModel({
    required this.id,
    required this.authorName,
    required this.authorInitial,
    required this.authorColor,
    required this.timeAgo,
    required this.text,
    this.likeCount = 0,
    this.replies = const [],
  });
}

class PostModel {
  final String id;
  final String authorName;
  final String authorInitial;
  final Color authorColor;
  final bool isOwnPost;
  final String timeAgo;
  final String content;
  final String? imageUrl;
  final int likeCount;
  final List<CommentModel> comments;

  const PostModel({
    required this.id,
    required this.authorName,
    required this.authorInitial,
    required this.authorColor,
    required this.isOwnPost,
    required this.timeAgo,
    required this.content,
    this.imageUrl,
    required this.likeCount,
    required this.comments,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Dummy posts
// ─────────────────────────────────────────────────────────────────────────────

final dummyPosts = <PostModel>[
  PostModel(
    id: 'p1',
    authorName: 'Ahmad',
    authorInitial: 'A',
    authorColor: const Color(0xFF6C4DFF),
    isOwnPost: true,
    timeAgo: 'Just now',
    content:
        'Completed my 30-day Morning Run streak today! 🏃 Never thought I\'d make it this far. '
        'Consistency really does compound over time — each run felt easier than the last.',
    likeCount: 47,
    comments: [
      CommentModel(
        id: 'c1',
        authorName: 'Sarah Jenkins',
        authorInitial: 'S',
        authorColor: const Color(0xFFEC407A),
        timeAgo: '5m ago',
        text: 'Incredible achievement! 30 days is no joke 🔥 Keep it going!',
        likeCount: 8,
        replies: [
          ReplyModel(
            id: 'r1',
            authorName: 'Ahmad',
            authorInitial: 'A',
            authorColor: const Color(0xFF6C4DFF),
            timeAgo: '3m ago',
            text: 'Thanks Sarah, your posts kept me motivated too! 🙏',
            likeCount: 3,
          ),
        ],
      ),
      CommentModel(
        id: 'c2',
        authorName: 'Mike Chen',
        authorInitial: 'M',
        authorColor: const Color(0xFF1E88E5),
        timeAgo: '12m ago',
        text: 'You\'re an inspiration to all of us here. Respect! 💪',
        likeCount: 5,
        replies: [],
      ),
      CommentModel(
        id: 'c3',
        authorName: 'Priya Sharma',
        authorInitial: 'P',
        authorColor: const Color(0xFFAB47BC),
        timeAgo: '18m ago',
        text: 'I just started my running habit last week because of your posts. Thank you! 🙏',
        likeCount: 11,
        replies: [
          ReplyModel(
            id: 'r2',
            authorName: 'Ahmad',
            authorInitial: 'A',
            authorColor: const Color(0xFF6C4DFF),
            timeAgo: '15m ago',
            text: 'That genuinely made my day Priya. You\'ve got this! 💪',
            likeCount: 6,
          ),
          ReplyModel(
            id: 'r3',
            authorName: 'Sarah Jenkins',
            authorInitial: 'S',
            authorColor: const Color(0xFFEC407A),
            timeAgo: '10m ago',
            text: 'Same here! Ahmad\'s streak inspired me to start logging daily too.',
            likeCount: 2,
          ),
        ],
      ),
    ],
  ),
  PostModel(
    id: 'p2',
    authorName: 'Sarah Jenkins',
    authorInitial: 'S',
    authorColor: const Color(0xFFEC407A),
    isOwnPost: false,
    timeAgo: '2h ago',
    content:
        'Hit my 2L water goal for the 7th day in a row 💧 It sounds simple but building '
        'this habit changed my energy levels completely. Anyone else notice a huge difference?',
    imageUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=800&q=80',
    likeCount: 89,
    comments: [
      CommentModel(
        id: 'c4',
        authorName: 'James Wilson',
        authorInitial: 'J',
        authorColor: const Color(0xFF5C6BC0),
        timeAgo: '1h ago',
        text: 'Yes! Hydration is so underrated. My skin cleared up too 😄',
        likeCount: 14,
        replies: [
          ReplyModel(
            id: 'r4',
            authorName: 'Sarah Jenkins',
            authorInitial: 'S',
            authorColor: const Color(0xFFEC407A),
            timeAgo: '55m ago',
            text: 'The skin glow is real!! Nobody told me about that side effect 😂',
            likeCount: 9,
          ),
        ],
      ),
      CommentModel(
        id: 'c5',
        authorName: 'Ahmad',
        authorInitial: 'A',
        authorColor: const Color(0xFF6C4DFF),
        timeAgo: '1h ago',
        text: 'Week 2 here as well! The afternoon energy slumps are basically gone.',
        likeCount: 7,
        replies: [],
      ),
    ],
  ),
  PostModel(
    id: 'p3',
    authorName: 'Mike Chen',
    authorInitial: 'M',
    authorColor: const Color(0xFF1E88E5),
    isOwnPost: false,
    timeAgo: '5h ago',
    content:
        'Read 20 pages every single day this week 📖 Currently halfway through '
        '"Atomic Habits" and it is genuinely reshaping how I think about building routines. '
        'Highly recommend to everyone on this app.',
    likeCount: 134,
    comments: [
      CommentModel(
        id: 'c6',
        authorName: 'Priya Sharma',
        authorInitial: 'P',
        authorColor: const Color(0xFFAB47BC),
        timeAgo: '4h ago',
        text: 'That book is what got me started on my mindfulness journey. Amazing read!',
        likeCount: 19,
        replies: [
          ReplyModel(
            id: 'r5',
            authorName: 'Mike Chen',
            authorInitial: 'M',
            authorColor: const Color(0xFF1E88E5),
            timeAgo: '3h ago',
            text: 'The identity-based habits chapter hit different. Completely changed my approach.',
            likeCount: 12,
          ),
          ReplyModel(
            id: 'r6',
            authorName: 'James Wilson',
            authorInitial: 'J',
            authorColor: const Color(0xFF5C6BC0),
            timeAgo: '2h ago',
            text: 'Adding this to my reading list right now. Thanks!',
            likeCount: 4,
          ),
        ],
      ),
      CommentModel(
        id: 'c7',
        authorName: 'Sarah Jenkins',
        authorInitial: 'S',
        authorColor: const Color(0xFFEC407A),
        timeAgo: '3h ago',
        text: 'The 2-minute rule alone is worth the whole book 😂',
        likeCount: 22,
        replies: [
          ReplyModel(
            id: 'r7',
            authorName: 'Ahmad',
            authorInitial: 'A',
            authorColor: const Color(0xFF6C4DFF),
            timeAgo: '2h ago',
            text: 'That rule is literally how I started my morning run. Start with 2 minutes 😄',
            likeCount: 15,
          ),
        ],
      ),
    ],
  ),
  PostModel(
    id: 'p4',
    authorName: 'Priya Sharma',
    authorInitial: 'P',
    authorColor: const Color(0xFFAB47BC),
    isOwnPost: false,
    timeAgo: '1d ago',
    content:
        'Day 15 of daily mindfulness meditation 🧘 I was a total skeptic at first — '
        'thought 10 minutes of sitting quietly was a waste of time. '
        'I could not have been more wrong. The clarity is unreal.',
    imageUrl: 'https://images.unsplash.com/photo-1593811167562-9cef47bfc4d7?w=800&q=80',
    likeCount: 212,
    comments: [
      CommentModel(
        id: 'c9',
        authorName: 'Ahmad',
        authorInitial: 'A',
        authorColor: const Color(0xFF6C4DFF),
        timeAgo: '22h ago',
        text: 'This is what got me to finally try it. On day 3 now!',
        likeCount: 17,
        replies: [
          ReplyModel(
            id: 'r8',
            authorName: 'Priya Sharma',
            authorInitial: 'P',
            authorColor: const Color(0xFFAB47BC),
            timeAgo: '21h ago',
            text: 'Day 3 is the hardest! Push through and it gets so much easier 🙏',
            likeCount: 8,
          ),
        ],
      ),
      CommentModel(
        id: 'c10',
        authorName: 'Mike Chen',
        authorInitial: 'M',
        authorColor: const Color(0xFF1E88E5),
        timeAgo: '20h ago',
        text: 'The skeptic-to-believer arc is real 😂 Same story for me at day 7.',
        likeCount: 13,
        replies: [],
      ),
    ],
  ),
  PostModel(
    id: 'p5',
    authorName: 'James Wilson',
    authorInitial: 'J',
    authorColor: const Color(0xFF5C6BC0),
    isOwnPost: false,
    timeAgo: '2d ago',
    content:
        'Two full weeks of 8-hour sleep on the dot 😴 I used to brag about surviving on 5 hours. '
        'My productivity, mood, and gym performance have all shot up. '
        'Sleep is not laziness — it is the ultimate performance tool.',
    likeCount: 178,
    comments: [
      CommentModel(
        id: 'c11',
        authorName: 'Sarah Jenkins',
        authorInitial: 'S',
        authorColor: const Color(0xFFEC407A),
        timeAgo: '2d ago',
        text: 'The "I\'ll sleep when I\'m dead" mindset needs to die 😅 Good on you!',
        likeCount: 31,
        replies: [
          ReplyModel(
            id: 'r9',
            authorName: 'James Wilson',
            authorInitial: 'J',
            authorColor: const Color(0xFF5C6BC0),
            timeAgo: '2d ago',
            text: 'Ha! I was the worst offender of that mindset. Total 180 now.',
            likeCount: 18,
          ),
        ],
      ),
      CommentModel(
        id: 'c12',
        authorName: 'Priya Sharma',
        authorInitial: 'P',
        authorColor: const Color(0xFFAB47BC),
        timeAgo: '1d ago',
        text: 'Pair it with the meditation habit and the results are even better!',
        likeCount: 9,
        replies: [],
      ),
    ],
  ),
];
