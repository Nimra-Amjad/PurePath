import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/insights/widgets/year_contribution_grid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit year card
//
//   Walk                                    100%  364d
//   ▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪
//   JAN      APR       JUL       OCT      DEC
//
// A whole-year contribution grid for one habit, with its completion percentage,
// scheduled-day count, and month markers.
// ─────────────────────────────────────────────────────────────────────────────

class HabitYearCard extends StatelessWidget {
  final HabitYearStat stat;

  /// date (local midnight) → set of habit ids completed that day.
  final Map<DateTime, Set<String>> history;

  final int year;

  const HabitYearCard({
    super.key,
    required this.stat,
    required this.history,
    required this.year,
  });

  static const _monthLabels = ['JAN', 'APR', 'JUL', 'OCT', 'DEC'];

  @override
  Widget build(BuildContext context) {
    final habit = stat.habit;
    final percent = _formatPercent(stat.progress);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 16,
                    color: kWhiteColor,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: AppTextStyles.bold.copyWith(
                  fontSize: 15,
                  color: habit.accentColor,
                ),
              ),
              Space.horizontal(8),
              Text(
                '${stat.completed}d',
                style: AppTextStyles.normal.copyWith(
                  fontSize: 13,
                  color: kLightGreyColor,
                ),
              ),
            ],
          ),
          Space.vertical(16),

          // ── Contribution grid ───────────────────────────────────────────────
          YearContributionGrid(habit: habit, history: history, year: year),
          Space.vertical(10),

          // ── Month markers ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in _monthLabels)
                Text(
                  label,
                  style: AppTextStyles.medium.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.5,
                    color: kLightGreyColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Whole number for 100, one decimal below that (e.g. "100", "82.1").
  String _formatPercent(double progress) {
    final value = progress * 100;
    if (value >= 100) return '100';
    return value.toStringAsFixed(1);
  }
}
