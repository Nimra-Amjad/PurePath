import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Month navigator
//
//   [ < ]        September 2026        [ > ]
//
// The forward arrow is disabled once the visible month is the current
// (real-world) month, so the user can't page into the future.
// ─────────────────────────────────────────────────────────────────────────────

class MonthNavigator extends StatelessWidget {
  final DateTime monthStart;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const MonthNavigator({
    super.key,
    required this.monthStart,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return monthStart.year == now.year && monthStart.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ArrowButton(icon: Icons.chevron_left, onTap: onPrevMonth),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(monthStart),
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 15,
              color: kWhiteColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        _ArrowButton(
          icon: Icons.chevron_right,
          onTap: onNextMonth,
          isDisabled: _isCurrentMonth,
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
