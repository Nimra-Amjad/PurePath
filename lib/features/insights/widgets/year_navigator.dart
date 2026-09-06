import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Year navigator
//
//   [ < ]            2026            [ > ]
//
// The forward arrow is disabled once the visible year is the current one, so the
// user can't page into the future.
// ─────────────────────────────────────────────────────────────────────────────

class YearNavigator extends StatelessWidget {
  final int year;
  final VoidCallback onPrevYear;
  final VoidCallback onNextYear;

  const YearNavigator({
    super.key,
    required this.year,
    required this.onPrevYear,
    required this.onNextYear,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentYear = year >= DateTime.now().year;
    return Row(
      children: [
        _ArrowButton(icon: Icons.chevron_left, onTap: onPrevYear),
        Expanded(
          child: Text(
            '$year',
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 15,
              color: kWhiteColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        _ArrowButton(
          icon: Icons.chevron_right,
          onTap: onNextYear,
          isDisabled: isCurrentYear,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDisabled;

  const _ArrowButton({
    required this.icon,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.3 : 1.0,
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kContainerColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kWhiteColor.withOpacityValue(0.06)),
          ),
          child: Icon(icon, size: 22, color: kWhiteColor),
        ),
      ),
    );
  }
}
