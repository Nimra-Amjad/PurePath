import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/space.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Badges page
//
// One coin = one day in the user's current consecutive-day streak. Each
// badge unlocks at a day-streak milestone. The first one lands at 10 days,
// then they grow apart so later badges feel earned.
//
// Thresholds are static — the user's current coin balance (read from
// UserBloc) is the only dynamic input.
// ─────────────────────────────────────────────────────────────────────────────

class BadgesPage extends StatelessWidget {
  const BadgesPage({super.key});

  // ── 20 badges, gated on consecutive-day streak ────────────────────────────
  static const _badges = <_BadgeData>[
    _BadgeData(emoji: '🌱', name: 'Ten Days',         description: '10 days in a row. Habit is taking root.',                         color: Color(0xFF4CAF50), threshold: 10),
    _BadgeData(emoji: '🔥', name: 'Three Weeks',      description: '21 straight days. Momentum is real.',                              color: Color(0xFFF97316), threshold: 21),
    _BadgeData(emoji: '⚡', name: 'One Month',        description: '30 days unbroken. A full month of showing up.',                    color: Color(0xFFFFB300), threshold: 30),
    _BadgeData(emoji: '💪', name: 'Six Weeks',        description: '45 days. The hard part is behind you.',                            color: Color(0xFF6C4DFF), threshold: 45),
    _BadgeData(emoji: '✅', name: 'Two Months',       description: '60 days strong. Habit is the new normal.',                         color: Color(0xFF26A69A), threshold: 60),
    _BadgeData(emoji: '🎯', name: 'Quarter Master',   description: '90 days — three months without a miss.',                           color: Color(0xFF1E88E5), threshold: 90),
    _BadgeData(emoji: '🌿', name: 'Steady Spring',    description: '120 days of consistency. Growth is compounding.',                  color: Color(0xFF22C55E), threshold: 120),
    _BadgeData(emoji: '🌳', name: 'Half Year',        description: '180 days. Half a year of unbroken effort.',                        color: Color(0xFF00897B), threshold: 180),
    _BadgeData(emoji: '🌟', name: 'Nine Months',      description: '270 days. Most people quit before this.',                          color: Color(0xFF9B82E8), threshold: 270),
    _BadgeData(emoji: '📚', name: 'One Year',         description: '365 days. A full year, every single day.',                         color: Color(0xFF5C6BC0), threshold: 365),
    _BadgeData(emoji: '💯', name: '500 Days',         description: '500-day streak. Rare air now.',                                    color: Color(0xFFF97316), threshold: 500),
    _BadgeData(emoji: '⭐', name: 'Two Years',        description: '730 days unbroken. This is identity, not effort.',                 color: Color(0xFFFFB300), threshold: 730),
    _BadgeData(emoji: '🌲', name: '1000 Days',        description: 'Four digits of consecutive wins.',                                 color: Color(0xFF2E7D32), threshold: 1000),
    _BadgeData(emoji: '🏃', name: 'Marathoner',       description: '1,500 days of discipline. Most lifestyles haven\'t lasted this.',  color: Color(0xFFEC407A), threshold: 1500),
    _BadgeData(emoji: '🦁', name: 'Five Years',       description: '1,825 days — five solid years.',                                   color: Color(0xFFFF8F00), threshold: 1825),
    _BadgeData(emoji: '🚀', name: '2000 Club',        description: '2,000 days. Few will ever stand here.',                            color: Color(0xFFE53935), threshold: 2000),
    _BadgeData(emoji: '🏆', name: 'Decade Bound',     description: '2,500 days, one streak. Heading for a decade.',                    color: Color(0xFFFFB300), threshold: 2500),
    _BadgeData(emoji: '🌺', name: 'In Full Bloom',    description: '3,000 days unbroken. A craft, not a phase.',                       color: Color(0xFFAB47BC), threshold: 3000),
    _BadgeData(emoji: '🏅', name: 'Hall of Fame',     description: '3,650 days — a full decade of unbroken effort.',                   color: Color(0xFF6C4DFF), threshold: 3650),
    _BadgeData(emoji: '👑', name: 'Legend',           description: '5,000 days. The streak is the life.',                              color: Color(0xFFFFB300), threshold: 5000),
  ];

  /// Total badge count for the "See all N" link on the profile page.
  static int get totalCount => _badges.length;

  /// Number of badges earned at [coins].
  /// Sequential: badges are sorted by threshold ascending, so the count is
  /// simply how many thresholds the user has crossed.
  static int earnedCountForCoins(int coins) {
    int count = 0;
    for (final b in _badges) {
      if (coins >= b.threshold) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Up to [count] earned (emoji, name) pairs for the profile preview row.
  /// Pulls the live coin balance from [UserBloc] so the preview updates
  /// the moment a badge is unlocked.
  static List<(String, String)> earnedPreviews(BuildContext context,
      {int count = 4}) {
    final coins = context.read<UserBloc>().state.user?.coins ?? 0;
    final earned = earnedCountForCoins(coins);
    return _badges
        .take(earned)
        .take(count)
        .map((b) => (b.emoji, b.name))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (a, b) => a.user?.coins != b.user?.coins,
      builder: (context, state) {
        final coins = state.user?.coins ?? 0;
        final earned = earnedCountForCoins(coins);
        final total = _badges.length;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: kWhiteColor,
            surfaceTintColor: kWhiteColor,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            shadowColor: kBlackColor.withOpacityValue(0.06),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: kBlackColor,
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Badges',
              style: AppTextStyles.bold.copyWith(fontSize: 18),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProgressBanner(
                  earned: earned,
                  total: total,
                  coins: coins,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _BadgeCard(
                      data: _badges[i],
                      coins: coins,
                      isEarned: i < earned,
                      isNext: i == earned,
                    ),
                    childCount: total,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress banner
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBanner extends StatelessWidget {
  final int earned;
  final int total;
  final int coins;

  const _ProgressBanner({
    required this.earned,
    required this.total,
    required this.coins,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightPurple,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 22)),
              Space.horizontal(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$coins-day streak · $earned of $total badges',
                      style: AppTextStyles.semiBold.copyWith(
                        fontSize: 15,
                        color: purple,
                      ),
                    ),
                    Space.vertical(2),
                    Text(
                      'Mark a habit done every day to keep your streak alive.',
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 12,
                        color: purple.withOpacityValue(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Space.vertical(12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : earned / total,
              minHeight: 7,
              backgroundColor: purple.withOpacityValue(0.15),
              valueColor: const AlwaysStoppedAnimation(purple),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge card
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeCard extends StatelessWidget {
  final _BadgeData data;
  final int coins;
  final bool isEarned;
  final bool isNext;

  const _BadgeCard({
    required this.data,
    required this.coins,
    required this.isEarned,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppBottomSheet.show(
        context,
        body: _BadgeDetailSheet(
          data: data,
          coins: coins,
          isEarned: isEarned,
          isNext: isNext,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(16),
          border: isEarned
              ? Border.all(color: data.color.withOpacityValue(0.4), width: 1.5)
              : isNext
                  ? Border.all(
                      color: data.color.withOpacityValue(0.6), width: 1.5)
                  : Border.all(color: border),
          boxShadow: isEarned
              ? [
                  BoxShadow(
                    color: data.color.withOpacityValue(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Opacity(
                  opacity: isEarned ? 1.0 : 0.35,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: data.color.withOpacityValue(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        data.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ),
                if (!isEarned)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isNext ? data.color : kGreyColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: kWhiteColor, width: 1.5),
                    ),
                    child: Icon(
                      isNext
                          ? Icons.arrow_upward_rounded
                          : Icons.lock_rounded,
                      size: 10,
                      color: kWhiteColor,
                    ),
                  ),
              ],
            ),
            Space.vertical(7),
            Text(
              data.name,
              textAlign: TextAlign.center,
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 11,
                color: isEarned
                    ? textPrimary
                    : isNext
                        ? data.color
                        : textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Space.vertical(6),
            if (isNext) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: data.progressFor(coins).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: border,
                  valueColor: AlwaysStoppedAnimation(
                    data.color.withOpacityValue(0.7),
                  ),
                ),
              ),
              Space.vertical(3),
              Text(
                '${coins.clamp(0, data.threshold)} / ${data.threshold} days',
                textAlign: TextAlign.center,
                style: AppTextStyles.normal.copyWith(
                  fontSize: 9,
                  color: data.color,
                ),
              ),
            ],
            if (isEarned)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: data.color.withOpacityValue(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Earned',
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 9,
                    color: data.color,
                  ),
                ),
              ),
            if (!isEarned && !isNext)
              Text(
                'Locked',
                style: AppTextStyles.normal.copyWith(
                  fontSize: 9,
                  color: kGreyColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge detail bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeDetailSheet extends StatelessWidget {
  final _BadgeData data;
  final int coins;
  final bool isEarned;
  final bool isNext;

  const _BadgeDetailSheet({
    required this.data,
    required this.coins,
    required this.isEarned,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final progress = data.progressFor(coins).clamp(0.0, 1.0);
    final toGo = (data.threshold - coins).clamp(0, data.threshold);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: data.color.withOpacityValue(isEarned ? 0.12 : 0.06),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Opacity(
                opacity: isEarned ? 1.0 : 0.45,
                child: Text(
                  data.emoji,
                  style: const TextStyle(fontSize: 34),
                ),
              ),
            ),
          ),
          Space.vertical(14),
          Text(
            data.name,
            style: AppTextStyles.bold.copyWith(fontSize: 20),
          ),
          Space.vertical(6),
          Text(
            data.description,
            style: AppTextStyles.normal.copyWith(
              fontSize: 14,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          Space.vertical(16),
          if (isNext) ...[
            Row(
              children: [
                Text(
                  '${coins.clamp(0, data.threshold)} / ${data.threshold} days',
                  style: AppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 13,
                    color: data.color,
                  ),
                ),
              ],
            ),
            Space.vertical(8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: border,
                valueColor: AlwaysStoppedAnimation(data.color),
              ),
            ),
            Space.vertical(16),
          ],
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isEarned
                  ? green.withOpacityValue(0.1)
                  : isNext
                      ? data.color.withOpacityValue(0.08)
                      : kLightGreyColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEarned
                      ? Icons.check_circle_rounded
                      : isNext
                          ? Icons.timer_rounded
                          : Icons.lock_rounded,
                  size: 16,
                  color: isEarned
                      ? green
                      : isNext
                          ? data.color
                          : textSecondary,
                ),
                Space.horizontal(6),
                Text(
                  isEarned
                      ? 'Earned'
                      : isNext
                          ? '$toGo days to go'
                          : 'Unlock previous badges first',
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 13,
                    color: isEarned
                        ? green
                        : isNext
                            ? data.color
                            : textSecondary,
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
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeData {
  final String emoji;
  final String name;
  final String description;
  final Color color;
  final int threshold;

  const _BadgeData({
    required this.emoji,
    required this.name,
    required this.description,
    required this.color,
    required this.threshold,
  });

  double progressFor(int coins) =>
      threshold == 0 ? 1.0 : coins / threshold;
}
