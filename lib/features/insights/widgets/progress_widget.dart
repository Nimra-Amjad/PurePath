import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/habit_model.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit progress widget
//
// Shows one row for a single habit's weekly completion.
//
// [stat] → a [HabitWeeklyStat] from [InsightsState.habitWeeklyStats]
// ─────────────────────────────────────────────────────────────────────────────

class ProgressWidget extends StatelessWidget {
  final HabitWeeklyStat stat;

  const ProgressWidget({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final color = stat.category.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kLightGreyColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Category emoji inside a tinted circle
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacityValue(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stat.category.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          Space.horizontal(12),

          // Title + completion label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.title,
                  style: AppTextStyles.medium.copyWith(fontSize: 14),
                ),
                Space.vertical(2),
                Text(
                  '${stat.completedDays} / ${stat.totalDays} days',
                  style: AppTextStyles.normal.copyWith(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Space.horizontal(12),

          // Progress bar + percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(stat.progress * 100).round()}%',
                style: AppTextStyles.semiBold.copyWith(
                  fontSize: 13,
                  color: color,
                ),
              ),
              Space.vertical(6),
              SizedBox(
                width: 90,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: stat.progress,
                    minHeight: 7,
                    backgroundColor: color.withOpacityValue(0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
