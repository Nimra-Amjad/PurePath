import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Week navigator
//
//   [ < ]      31 Aug – 6 Sep 2026      [ > ]
//
// The centered label reads the visible week's range. The forward arrow is
// disabled once the visible week is the current (real-world) week so the user
// can't page into the future.
// ─────────────────────────────────────────────────────────────────────────────

class WeekNavigator extends StatelessWidget {
  final DateTime weekStart;
  final DateTime weekEnd;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;

  const WeekNavigator({
    super.key,
    required this.weekStart,
    required this.weekEnd,
    required this.onPrevWeek,
    required this.onNextWeek,
  });

  bool get _isCurrentWeek {
    final now = DateTime.now();
    final thisMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return weekStart == thisMonday;
  }

  String get _rangeLabel {
    final startDay = DateFormat('d').format(weekStart);
    final endFull = DateFormat('d MMM yyyy').format(weekEnd);

    if (weekStart.month == weekEnd.month) {
      return '$startDay – $endFull';
    }
    final startFull = DateFormat('d MMM').format(weekStart);
    return '$startFull – $endFull';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ArrowButton(icon: Icons.chevron_left, onTap: onPrevWeek),
        Expanded(
          child: Text(
            _rangeLabel,
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 15,
              color: kWhiteColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        _ArrowButton(
          icon: Icons.chevron_right,
          onTap: onNextWeek,
          isDisabled: _isCurrentWeek,
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
