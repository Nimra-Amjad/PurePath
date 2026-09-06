import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Insights period
//
// The three time ranges the insights screen can show. Only [weekly] is built
// out for now — [monthly] and [yearly] show a "coming soon" placeholder.
// ─────────────────────────────────────────────────────────────────────────────

enum InsightsPeriod {
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  const InsightsPeriod(this.label);

  final String label;
}

// ─────────────────────────────────────────────────────────────────────────────
// Period tabs
//
// A pill-shaped segmented control. The selected segment is filled with the lime
// accent and dark text; the others are transparent with grey text.
// ─────────────────────────────────────────────────────────────────────────────

class PeriodTabs extends StatelessWidget {
  final InsightsPeriod selected;
  final ValueChanged<InsightsPeriod> onChanged;

  const PeriodTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final period in InsightsPeriod.values)
            Expanded(
              child: _Segment(
                label: period.label,
                isSelected: period == selected,
                onTap: () => onChanged(period),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryGreenColor : kTransparentColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: AppTextStyles.semiBold.copyWith(
            fontSize: 14,
            color: isSelected ? kBlackColor : kLightGreyColor,
          ),
        ),
      ),
    );
  }
}
