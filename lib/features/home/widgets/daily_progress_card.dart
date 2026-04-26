import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/day_summary.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Daily progress card
//
// Shows a circular indicator + "X of Y habits completed" for the selected day.
// Receives a [DaySummary] from HomeState — pure display, no business logic.
// ─────────────────────────────────────────────────────────────────────────────

class DailyProgressCard extends StatelessWidget {
  final DaySummary summary;

  const DailyProgressCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kBlackColor.withOpacityValue(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 70,
            width: 70,
            child: CircularProgressIndicator(
              value: summary.overallProgress,
              strokeWidth: 8,
              color: purple,
              backgroundColor: lightPurple,
            ),
          ),
          Space.horizontal(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TODAY'S PROGRESS",
                style: AppTextStyles.normal.copyWith(color: kDarkGreyColor),
              ),
              Space.vertical(6),
              Text(
                '${summary.completedCount} of ${summary.totalCount}',
                style: AppTextStyles.bold.copyWith(fontSize: 22),
              ),
              Text(
                'habits completed',
                style: AppTextStyles.normal.copyWith(color: kDarkGreyColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
