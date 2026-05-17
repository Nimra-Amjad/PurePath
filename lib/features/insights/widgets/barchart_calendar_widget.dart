import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/custom_arrow_button_filled.dart';
import 'package:purepath/core/widgets/space.dart';

class BarchartCalendarWidget extends StatelessWidget {
  final DateTime weekStart;
  final DateTime weekEnd;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;

  const BarchartCalendarWidget({
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
    } else {
      final startFull = DateFormat('d MMM').format(weekStart);
      return '$startFull – $endFull';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CustomArrowButtonFilled(
          svgAsset: Assets.svgArrowBackIcon,
          onTap: onPrevWeek,
          isDisabled: false,
        ),
        Space.horizontal(10),
        Expanded(
          child: Text(
            _rangeLabel,
            style: AppTextStyles.medium.copyWith(
              fontSize: 14,
              color: kWhiteColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Space.horizontal(10),
        CustomArrowButtonFilled(
          svgAsset: Assets.svgArrowForwardIcon,
          onTap: onNextWeek,
          isDisabled: _isCurrentWeek,
        ),
      ],
    );
  }
}
