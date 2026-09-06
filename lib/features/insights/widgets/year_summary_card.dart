import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Year summary card
//
//   DAYS COMPLETED IN 2026
//   1490
//
// Shows the total completed habit-days for the visible year.
// ─────────────────────────────────────────────────────────────────────────────

class YearSummaryCard extends StatelessWidget {
  final int year;
  final int daysCompleted;

  const YearSummaryCard({
    super.key,
    required this.year,
    required this.daysCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAYS COMPLETED IN $year',
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 12,
              letterSpacing: 1.2,
              color: kLightGreyColor,
            ),
          ),
          Space.vertical(6),
          Text(
            '$daysCompleted',
            style: AppTextStyles.bold.copyWith(
              fontSize: 52,
              height: 1.0,
              color: kPrimaryGreenColor,
            ),
          ),
        ],
      ),
    );
  }
}
