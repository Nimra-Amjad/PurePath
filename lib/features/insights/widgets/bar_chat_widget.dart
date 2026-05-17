import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/day_summary.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Bar chart widget
//
// Renders one vertical bar per day (Mon → Sun) whose height represents the
// overall habit-completion progress for that day (0.0 → 1.0).
//
// [summaries] → 7 [DaySummary] entries from [InsightsState.visibleWeekSummaries]
// ─────────────────────────────────────────────────────────────────────────────

class BarChartWidget extends StatelessWidget {
  final List<DaySummary> summaries;

  const BarChartWidget({super.key, required this.summaries});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: kBlackColor.withOpacityValue(0.06), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Overview',
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 14,
              color: kWhiteColor,
            ),
          ),
          Space.vertical(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: summaries.map((day) => _BarItem(summary: day)).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single bar item
// ─────────────────────────────────────────────────────────────────────────────

class _BarItem extends StatelessWidget {
  final DaySummary summary;

  const _BarItem({required this.summary});

  bool get _isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return summary.date == today;
  }

  @override
  Widget build(BuildContext context) {
    final progress = summary.overallProgress;
    final dayLabel = DateFormat('EEE').format(summary.date).toUpperCase();
    final barColor = _isToday
        ? kDarkGreenColor
        : kLightGreenColor.withOpacityValue(0.5);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Percentage label above bar (only when > 0)
        Text(
          progress > 0 ? '${(progress * 100).round()}%' : '',
          style: AppTextStyles.normal.copyWith(
            fontSize: 10,
            color: textSecondary,
          ),
        ),
        Space.vertical(4),

        // Bar
        SizedBox(
          height: 120,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Background track
              Container(
                width: 36,
                decoration: BoxDecoration(
                  color: kPrimaryGreyColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              // Filled portion
              FractionallySizedBox(
                heightFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  width: 36,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Space.vertical(8),

        // Day label
        Text(
          dayLabel,
          style: AppTextStyles.normal.copyWith(
            fontSize: 11,
            color: _isToday
                ? kDarkGreenColor
                : kLightGreenColor.withOpacityValue(0.5),
            fontWeight: _isToday ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
