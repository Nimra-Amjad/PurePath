import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/space.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Badges page — sequential unlocking
//
// Badges unlock one by one in order.
// Badge N can only be earned after badge N-1 is earned.
// ─────────────────────────────────────────────────────────────────────────────

// ── Simulated user stats ──────────────────────────────────────────────────────
const _userStreak = 23;
const _userCheckIns = 142;
const _userHabits = 6;
const _userPerfectDays = 4;

class BadgesPage extends StatelessWidget {
  const BadgesPage({super.key});

  // ── 20 badges ordered from easiest → hardest ──────────────────────────────
  //
  // Sequential rule: badge N is earned only if badges 1…N-1 are all earned
  // AND badge N's own requirement is met by the user's stats.
  //
  // Ordering logic:
  //   Badges 1–4   : intro streak milestones (1 → 3 → 7 → 14 days)
  //   Badges 5–6   : early check-in engagement (10 → 25)
  //   Badges 7–8   : first habit milestones (1 → 3 habits)
  //   Badges 9–11  : mid-game streak + check-ins (21 days, 50, 100 check-ins)
  //   Badge  12    : first perfect day
  //   Badges 13–14 : habit depth (5 → 8 habits)
  //   Badges 15–17 : advanced streak (30 → 45 → 60 days)
  //   Badges 18–19 : perfect-day mastery (3 → 7 perfect days)
  //   Badge  20    : legend (30 perfect days)

  static final _badges = <_BadgeData>[
    _BadgeData(
      emoji: '🌱',
      name: 'Day One',
      description: 'Start your streak — show up for just one day.',
      color: Color(0xFF4CAF50),
      unit: 'day streak',
      requiredValue: 1,
      currentValue: _userStreak,
    ),
    _BadgeData(
      emoji: '🔥',
      name: 'On Fire',
      description: 'Keep the flame alive for 3 days straight.',
      color: Color(0xFFF97316),
      unit: 'day streak',
      requiredValue: 3,
      currentValue: _userStreak,
    ),
    _BadgeData(
      emoji: '⚡',
      name: 'Week Strong',
      description: 'Seven days in — you\'re building real momentum.',
      color: Color(0xFFFFB300),
      unit: 'day streak',
      requiredValue: 7,
      currentValue: _userStreak,
    ),
    _BadgeData(
      emoji: '💪',
      name: 'Two Weeks In',
      description: 'Fourteen days of showing up. Habit is forming.',
      color: Color(0xFF6C4DFF),
      unit: 'day streak',
      requiredValue: 14,
      currentValue: _userStreak,
    ),
    _BadgeData(
      emoji: '✅',
      name: 'Getting Real',
      description: 'Complete 10 check-ins. Consistency is clicking.',
      color: Color(0xFF26A69A),
      unit: 'check-ins',
      requiredValue: 10,
      currentValue: _userCheckIns,
    ),
    _BadgeData(
      emoji: '🎯',
      name: 'On Target',
      description: '25 check-ins done. You\'re dialled in.',
      color: Color(0xFF1E88E5),
      unit: 'check-ins',
      requiredValue: 25,
      currentValue: _userCheckIns,
    ),
    _BadgeData(
      emoji: '🌿',
      name: 'First Habit',
      description: 'You\'ve created and stuck with your first habit.',
      color: Color(0xFF22C55E),
      unit: 'active habits',
      requiredValue: 1,
      currentValue: _userHabits,
    ),
    _BadgeData(
      emoji: '🌳',
      name: 'Triple Habit',
      description: 'Three active habits running at once. Impressive.',
      color: Color(0xFF00897B),
      unit: 'active habits',
      requiredValue: 3,
      currentValue: _userHabits,
    ),
    _BadgeData(
      emoji: '🌟',
      name: 'Three Weeks',
      description: 'A 21-day streak — almost a month of discipline.',
      color: Color(0xFF9B82E8),
      unit: 'day streak',
      requiredValue: 21,
      currentValue: _userStreak,
    ),
    _BadgeData(
      emoji: '📚',
      name: 'Half Century',
      description: '50 check-ins completed. Building a library of wins.',
      color: Color(0xFF5C6BC0),
      unit: 'check-ins',
      requiredValue: 50,
      currentValue: _userCheckIns,
    ),
    _BadgeData(
      emoji: '💯',
      name: 'Century Club',
      description: '100 check-ins — you\'ve crossed a major milestone.',
      color: Color(0xFFF97316),
      unit: 'check-ins',
      requiredValue: 100,
      currentValue: _userCheckIns,
    ),
    _BadgeData(
      emoji: '⭐',
      name: 'Perfect Day',
      description: 'Every habit completed in a single day. Flawless.',
      color: Color(0xFFFFB300),
      unit: 'perfect days',
      requiredValue: 1,
      currentValue: _userPerfectDays,
    ),
    _BadgeData(
      emoji: '🌲',
      name: 'Habit Builder',
      description: 'Five active habits — you\'re reshaping your lifestyle.',
      color: Color(0xFF2E7D32),
      unit: 'active habits',
      requiredValue: 5,
      currentValue: _userHabits,
    ),
    _BadgeData(
      emoji: '🏃',
      name: 'Month Strong',
      description: 'Thirty days straight. A full month of commitment.',
      color: Color(0xFFEC407A),
      unit: 'day streak',
      requiredValue: 30,
      currentValue: _userStreak,
    ),
    _BadgeData(
      emoji: '🦁',
      name: 'Habit Juggler',
      description: 'Eight active habits running. You manage it all.',
      color: Color(0xFFFF8F00),
      unit: 'active habits',
      requiredValue: 8,
      currentValue: _userHabits,
    ),
    _BadgeData(
      emoji: '🚀',
      name: '45-Day Streak',
      description: 'Forty-five days of pure discipline. Unstoppable.',
      color: Color(0xFFE53935),
      unit: 'day streak',
      requiredValue: 45,
      currentValue: _userStreak,
    ),
    _BadgeData(
      emoji: '🏆',
      name: 'Grand Champion',
      description: 'A 60-day streak. You are among the elite.',
      color: Color(0xFFFFB300),
      unit: 'day streak',
      requiredValue: 60,
      currentValue: _userStreak,
    ),
    _BadgeData(
      emoji: '🌺',
      name: 'Triple Perfection',
      description: 'Three perfect days — flawless becomes a pattern.',
      color: Color(0xFFAB47BC),
      unit: 'perfect days',
      requiredValue: 3,
      currentValue: _userPerfectDays,
    ),
    _BadgeData(
      emoji: '🏅',
      name: 'Flawless Week',
      description: 'Seven perfect days. Every single habit, every day.',
      color: Color(0xFF6C4DFF),
      unit: 'perfect days',
      requiredValue: 7,
      currentValue: _userPerfectDays,
    ),
    _BadgeData(
      emoji: '👑',
      name: 'Legend',
      description: 'Thirty perfect days. You have truly mastered habits.',
      color: Color(0xFFFFB300),
      unit: 'perfect days',
      requiredValue: 30,
      currentValue: _userPerfectDays,
    ),
  ];

  // Sequential earned count: badges 1..N are all earned where N is the first
  // badge whose requirement is NOT met. Stops at first unmet requirement.
  static int get _earnedCount {
    int count = 0;
    for (final b in _badges) {
      if (b.currentValue >= b.requiredValue) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Total number of badges (for the "See all N" label on the profile page).
  static int get totalCount => _badges.length;

  /// Returns up to [count] earned badge (emoji, name) pairs for use in
  /// profile page previews.
  static List<(String, String)> earnedPreviews({int count = 4}) {
    final earned = _earnedCount;
    return _badges
        .take(earned)
        .take(count)
        .map((b) => (b.emoji, b.name))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final earned = _earnedCount;
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Badges',
          style: AppTextStyles.bold.copyWith(fontSize: 18),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Progress banner ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProgressBanner(earned: earned, total: total),
          ),

          // ── Flat sequential badge grid ───────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _BadgeCard(
                  data: _badges[i],
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress banner
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBanner extends StatelessWidget {
  final int earned;
  final int total;
  const _ProgressBanner({required this.earned, required this.total});

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
              const Text('🏅', style: TextStyle(fontSize: 22)),
              Space.horizontal(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$earned of $total badges earned',
                      style: AppTextStyles.semiBold.copyWith(
                        fontSize: 15,
                        color: purple,
                      ),
                    ),
                    Space.vertical(2),
                    Text(
                      'Keep building habits to unlock more!',
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
              value: earned / total,
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
  final bool isEarned;
  final bool isNext; // the very next badge to unlock

  const _BadgeCard({
    required this.data,
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
                  ? Border.all(color: data.color.withOpacityValue(0.6), width: 1.5)
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
            // ── Emoji circle ─────────────────────────────────────────────
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

            // ── Name ─────────────────────────────────────────────────────
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

            // ── Progress bar (next badge only) ────────────────────────────
            if (isNext) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: data.progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: border,
                  valueColor: AlwaysStoppedAnimation(
                    data.color.withOpacityValue(0.7),
                  ),
                ),
              ),
              Space.vertical(3),
              Text(
                '${data.currentValue.clamp(0, data.requiredValue)}/${data.requiredValue} ${data.unit}',
                textAlign: TextAlign.center,
                style: AppTextStyles.normal.copyWith(
                  fontSize: 9,
                  color: data.color,
                ),
              ),
            ],

            // ── Earned chip ───────────────────────────────────────────────
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

            // ── Locked chip ───────────────────────────────────────────────
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
  final bool isEarned;
  final bool isNext;

  const _BadgeDetailSheet({
    required this.data,
    required this.isEarned,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final toGo = (data.requiredValue - data.currentValue.clamp(0, data.requiredValue));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji
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

          // Progress bar — shown for the next badge
          if (isNext) ...[
            Row(
              children: [
                Text(
                  '${data.currentValue.clamp(0, data.requiredValue)} / ${data.requiredValue} ${data.unit}',
                  style: AppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(data.progress * 100).round()}%',
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
                value: data.progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: border,
                valueColor: AlwaysStoppedAnimation(data.color),
              ),
            ),
            Space.vertical(16),
          ],

          // Status chip
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
                          ? '$toGo ${data.unit} to go'
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
  final String unit;
  final int requiredValue;
  final int currentValue;

  const _BadgeData({
    required this.emoji,
    required this.name,
    required this.description,
    required this.color,
    required this.unit,
    required this.requiredValue,
    required this.currentValue,
  });

  double get progress =>
      requiredValue == 0 ? 1.0 : currentValue / requiredValue;
}
