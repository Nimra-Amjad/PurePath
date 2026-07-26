import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/custom_back_button.dart';
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

  static const _badges = <_BadgeData>[
    _BadgeData(emoji: '🌱', name: 'First Step',       description: '10 XP. The path begins.',                                  color: Color(0xFF4CAF50), threshold: 10),
    _BadgeData(emoji: '🔥', name: 'Spark',            description: '21 XP. Momentum catches fire.',                            color: Color(0xFFF97316), threshold: 21),
    _BadgeData(emoji: '⚡', name: 'Pure Month',       description: '30 XP. A full cycle of light.',                            color: Color(0xFFFFB300), threshold: 30),
    _BadgeData(emoji: '💪', name: 'Steel Will',       description: '45 XP. The hardest part is behind you.',                   color: Color(0xFF6C4DFF), threshold: 45),
    _BadgeData(emoji: '✅', name: 'Foundation',       description: '60 XP. The habit is laid in stone.',                       color: Color(0xFF26A69A), threshold: 60),
    _BadgeData(emoji: '🎯', name: 'Quarter Master',   description: '90 XP earned through consistent effort.',                  color: Color(0xFF1E88E5), threshold: 90),
    _BadgeData(emoji: '🌿', name: 'Steady Flame',     description: '120 XP. Quiet, unshakable progress.',                      color: Color(0xFF22C55E), threshold: 120),
    _BadgeData(emoji: '🌳', name: 'Half-Year Hero',   description: '180 XP. Half a year of pure effort.',                      color: Color(0xFF00897B), threshold: 180),
    _BadgeData(emoji: '🌟', name: 'Nine-Month Soul',  description: '270 XP. Most people never reach this.',                    color: Color(0xFF9B82E8), threshold: 270),
    _BadgeData(emoji: '📚', name: 'Year of Light',    description: '365 XP. A full year of dedication.',                       color: Color(0xFF5C6BC0), threshold: 365),
    _BadgeData(emoji: '💯', name: 'Iron Pact',        description: '500 XP. The promise you kept to yourself.',                color: Color(0xFFF97316), threshold: 500),
    _BadgeData(emoji: '⭐', name: 'Identity Shift',   description: "730 XP. This isn't effort — this is who you are.",         color: Color(0xFFFFB300), threshold: 730),
    _BadgeData(emoji: '🌲', name: 'Thousand Suns',    description: '1,000 XP. Four digits of pure discipline.',                color: Color(0xFF2E7D32), threshold: 1000),
    _BadgeData(emoji: '🏃', name: 'Marathoner',       description: '1,500 XP. Few have walked this far.',                      color: Color(0xFFEC407A), threshold: 1500),
    _BadgeData(emoji: '🦁', name: 'Ironclad',         description: '1,825 XP. Years of light, earned one day at a time.',      color: Color(0xFFFF8F00), threshold: 1825),
    _BadgeData(emoji: '🚀', name: 'Mountain Mover',   description: '2,000 XP. The unmovable becomes you.',                     color: Color(0xFFE53935), threshold: 2000),
    _BadgeData(emoji: '🏆', name: 'Path of Pure',     description: '2,500 XP. A craft, not a phase.',                          color: Color(0xFFFFB300), threshold: 2500),
    _BadgeData(emoji: '🌺', name: "Sage's Path",      description: '3,000 XP. Wisdom written in dedication.',                  color: Color(0xFFAB47BC), threshold: 3000),
    _BadgeData(emoji: '🏅', name: 'Decade of Light',  description: '3,650 XP. A decade of pure effort.',                       color: Color(0xFF6C4DFF), threshold: 3650),
    _BadgeData(emoji: '👑', name: 'Pure Legend',      description: '5,000 XP. The path is the life.',                          color: Color(0xFFFFB300), threshold: 5000),
  ];

  /// Total badge count for the "See all N" link on the profile page.
  static int get totalCount => _badges.length;

  /// Number of badges earned at [xp].
  /// Sequential: badges are sorted by threshold ascending, so the count is
  /// simply how many thresholds the user has crossed.
  static int earnedCountForXp(int xp) {
    int count = 0;
    for (final b in _badges) {
      if (xp >= b.threshold) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Up to [count] earned (emoji, name) pairs for the profile preview row.
  /// Pulls the live XP from [UserBloc] so the preview updates the moment a
  /// badge is unlocked.
  static List<(String, String)> earnedPreviews(
    BuildContext context, {
    int count = 4,
  }) {
    final xp = context.read<UserBloc>().state.user?.streak ?? 0;
    final earned = earnedCountForXp(xp);
    return _badges
        .take(earned)
        .take(count)
        .map((b) => (b.emoji, b.name))
        .toList();
  }

  /// First [count] badges with their earned state, for the profile preview.
  /// Always returns [count] entries (or fewer if the catalog is smaller) so
  /// the preview row has a stable layout.
  static List<({String emoji, String name, bool isEarned})> firstNPreviews(
    BuildContext context, {
    int count = 5,
  }) {
    final xp = context.read<UserBloc>().state.user?.streak ?? 0;
    return _badges
        .take(count)
        .map((b) => (emoji: b.emoji, name: b.name, isEarned: xp >= b.threshold))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (a, b) => a.user?.streak != b.user?.streak,
      builder: (context, state) {
        final xp = state.user?.streak ?? 0;
        final earned = earnedCountForXp(xp);
        final total = _badges.length;

        return Scaffold(
          backgroundColor: kScaffoldColor,
          appBar: AppBar(
            backgroundColor: kScaffoldColor,
            surfaceTintColor: kScaffoldColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CustomBackButton(onTap: () => context.pop()),
            ),
            title: Text(
              'Badges',
              style: AppTextStyles.bold.copyWith(
                fontSize: 18,
                color: kWhiteColor,
              ),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProgressBanner(
                  earned: earned,
                  total: total,
                  xp: xp,
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
                      xp: xp,
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
  final int xp;

  const _ProgressBanner({
    required this.earned,
    required this.total,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryGreyColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 22)),
              Space.horizontal(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$xp XP · $earned of $total badges',
                      style: AppTextStyles.semiBold.copyWith(
                        fontSize: 15,
                        color: kWhiteColor,
                      ),
                    ),
                    Space.vertical(2),
                    Text(
                      'Complete habits to earn XP and unlock badges.',
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 12,
                        color: kLightGreyColor.withOpacityValue(0.8),
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
              backgroundColor: kContainerColorContrast,
              valueColor: const AlwaysStoppedAnimation(kPrimaryGreenColor),
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
  final int xp;
  final bool isEarned;
  final bool isNext;

  const _BadgeCard({
    required this.data,
    required this.xp,
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
          xp: xp,
          isEarned: isEarned,
          isNext: isNext,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        decoration: BoxDecoration(
          color: kContainerColor,
          borderRadius: BorderRadius.circular(16),
          border: isEarned
              ? Border.all(color: data.color.withOpacityValue(0.55), width: 1.5)
              : isNext
                  ? Border.all(
                      color: data.color.withOpacityValue(0.6),
                      width: 1.5,
                    )
                  : Border.all(color: kPrimaryGreyColor, width: 0.8),
          boxShadow: isEarned
              ? [
                  BoxShadow(
                    color: data.color.withOpacityValue(0.18),
                    blurRadius: 10,
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
                  opacity: isEarned ? 1.0 : 0.4,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: data.color.withOpacityValue(0.18),
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
                      color: isNext ? data.color : kPrimaryGreyColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: kContainerColor, width: 1.5),
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
                    ? kWhiteColor
                    : isNext
                        ? data.color
                        : kLightGreyColor.withOpacityValue(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Space.vertical(6),
            if (isNext) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: data.progressFor(xp).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: kContainerColorContrast,
                  valueColor: AlwaysStoppedAnimation(
                    data.color.withOpacityValue(0.85),
                  ),
                ),
              ),
              Space.vertical(3),
              Text(
                '${xp.clamp(0, data.threshold)} / ${data.threshold} XP',
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
                  color: data.color.withOpacityValue(0.18),
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
                  color: kLightGreyColor.withOpacityValue(0.5),
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
  final int xp;
  final bool isEarned;
  final bool isNext;

  const _BadgeDetailSheet({
    required this.data,
    required this.xp,
    required this.isEarned,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final progress = data.progressFor(xp).clamp(0.0, 1.0);
    final toGo = (data.threshold - xp).clamp(0, data.threshold);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: data.color.withOpacityValue(isEarned ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Opacity(
                opacity: isEarned ? 1.0 : 0.5,
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
            style: AppTextStyles.bold.copyWith(
              fontSize: 20,
              color: kWhiteColor,
            ),
          ),
          Space.vertical(6),
          Text(
            data.description,
            style: AppTextStyles.normal.copyWith(
              fontSize: 14,
              color: kLightGreyColor.withOpacityValue(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          Space.vertical(16),
          if (isNext) ...[
            Row(
              children: [
                Text(
                  '${xp.clamp(0, data.threshold)} / ${data.threshold} XP',
                  style: AppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: kLightGreyColor,
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
                backgroundColor: kContainerColorContrast,
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
                  ? kPrimaryGreenColor.withOpacityValue(0.18)
                  : isNext
                      ? data.color.withOpacityValue(0.15)
                      : kContainerColorContrast,
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
                      ? kPrimaryGreenColor
                      : isNext
                          ? data.color
                          : kLightGreyColor,
                ),
                Space.horizontal(6),
                Text(
                  isEarned
                      ? 'Earned'
                      : isNext
                          ? '$toGo XP to go'
                          : 'Unlock previous badges first',
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 13,
                    color: isEarned
                        ? kPrimaryGreenColor
                        : isNext
                            ? data.color
                            : kLightGreyColor,
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

  double progressFor(int xp) =>
      threshold == 0 ? 1.0 : xp / threshold;
}
