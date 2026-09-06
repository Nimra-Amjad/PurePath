import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';

// ─────────────────────────────────────────────────────────────────────────────
// No habits scheduled view
//
// Shown on the Monthly/Yearly Insights tabs when the user has habits, but none
// of them were scheduled to run during the visible month/year (e.g. paging to
// a year before any habit existed, or a custom schedule that skips the whole
// period). Distinct from [InsightsEmptyView], which only covers "no habits
// created yet".
// ─────────────────────────────────────────────────────────────────────────────

class NoHabitsScheduledView extends StatelessWidget {
  /// e.g. "September 2026" or "2026".
  final String periodLabel;

  const NoHabitsScheduledView({super.key, required this.periodLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryGreenColor.withOpacityValue(0.35),
            kWhiteColor.withOpacityValue(0.04),
          ],
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kContainerColor, kContainerColorContrast],
          ),
        ),
        child: Column(
          children: [
            // ── Glowing badge ──────────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kPrimaryGreenColor.withOpacityValue(0.2),
                    kPrimaryGreenColor.withOpacityValue(0.05),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryGreenColor.withOpacityValue(0.25),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: kPrimaryGreenColor,
                size: 32,
              ),
            ),
            Space.vertical(20),

            // ── Heading ──────────────────────────────────────────────────
            Text(
              'Nothing scheduled',
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 18,
                color: kWhiteColor,
              ),
              textAlign: TextAlign.center,
            ),
            Space.vertical(8),

            // ── Subtext ──────────────────────────────────────────────────
            Text(
              'None of your habits were scheduled to run in $periodLabel.',
              style: AppTextStyles.normal.copyWith(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
