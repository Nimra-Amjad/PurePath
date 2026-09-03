import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit progress widget
//
// A single habit's weekly completion card:
//
//   ┌────────────────────────────────────────────┐
//   │  [icon]  Title                        57%   │
//   │          4 of 7 days                        │
//   │  ▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
//   └────────────────────────────────────────────┘
//
// The full-width bar makes progress readable at a glance, and everything is
// tinted with the habit's category [color] so rows stay visually distinct.
//
// [stat] → a [HabitWeeklyStat] from [InsightsState.habitWeeklyStats]
// ─────────────────────────────────────────────────────────────────────────────

class ProgressWidget extends StatelessWidget {
  final HabitWeeklyStat stat;

  const ProgressWidget({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    const color = kHabitAccentColor;
    final percent = (stat.progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kWhiteColor.withOpacityValue(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ── Category emoji inside a tinted rounded tile ──────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacityValue(0.16),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: color.withOpacityValue(0.22)),
                ),
                child: const Center(
                  child: Text(
                    kHabitEmoji,
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              Space.horizontal(12),

              // ── Title + completion label ─────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.semiBold.copyWith(
                        fontSize: 15,
                        color: kWhiteColor,
                      ),
                    ),
                    Space.vertical(2),
                    Text(
                      '${stat.completedDays} of ${stat.totalDays} days',
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 12.5,
                        color: kSecondaryGreyColor,
                      ),
                    ),
                  ],
                ),
              ),
              Space.horizontal(10),

              // ── Percentage badge ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacityValue(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percent%',
                  style: AppTextStyles.bold.copyWith(
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Space.vertical(14),

          // ── Full-width progress bar ────────────────────────────────────────
          _ProgressBar(value: stat.progress, color: color),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A rounded, gradient-filled progress bar with a soft glow.
//
// Built on a Stack instead of [LinearProgressIndicator] so the fill can carry
// a gradient + shadow and the corners stay fully rounded at any value.
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const _ProgressBar({required this.value, required this.color});

  static const double _height = 8;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(_height),
      child: Stack(
        children: [
          // Track
          Container(
            height: _height,
            width: double.infinity,
            color: color.withOpacityValue(0.12),
          ),
          // Fill — animates from empty to [clamped] on first build, and eases
          // to the new value whenever [value] changes.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: animatedValue,
                child: child,
              );
            },
            child: Container(
              height: _height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_height),
                gradient: LinearGradient(
                  colors: [color.withOpacityValue(0.65), color],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacityValue(0.45),
                    blurRadius: 6,
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
