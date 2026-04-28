import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Barchart calendar widget
//
// Shows the currently visible week range (e.g. "21 Apr – 27 Apr 2026")
// with prev/next arrow buttons. Purely display — no business logic.
//
// [weekStart]    → Monday of the visible week
// [weekEnd]      → Sunday of the visible week (weekStart + 6)
// [onPrevWeek]   → called when the user taps ‹
// [onNextWeek]   → called when the user taps ›
// ─────────────────────────────────────────────────────────────────────────────

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

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// True when [weekStart] is the Monday of the current real-world week.
  /// Used to disable the forward arrow — the user can't see future data.
  bool get _isCurrentWeek {
    final now = DateTime.now();
    final thisMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return weekStart == thisMonday;
  }

  // ── Date label ─────────────────────────────────────────────────────────────
  //
  // • Same month   → "21 – 27 Apr 2026"
  // • Spans months → "28 Apr – 4 May 2026"

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
        // ── Previous week ────────────────────────────────────────────────────
        _ArrowButton(
          svgAsset: Assets.svgArrowBackIcon,
          onTap: onPrevWeek,
        ),
        Space.horizontal(10),

        // ── Week range label ─────────────────────────────────────────────────
        Expanded(
          child: Text(
            _rangeLabel,
            style: AppTextStyles.medium.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        Space.horizontal(10),

        // ── Next week (disabled on current week) ─────────────────────────────
        _ArrowButton(
          svgAsset: Assets.svgArrowForwardIcon,
          onTap: onNextWeek,
          isDisabled: _isCurrentWeek,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arrow button
// ─────────────────────────────────────────────────────────────────────────────

class _ArrowButton extends StatelessWidget {
  final String svgAsset;
  final VoidCallback onTap;

  /// When true the button is shown at reduced opacity and ignores taps.
  final bool isDisabled;

  const _ArrowButton({
    required this.svgAsset,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1.0,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: kLightGreyColor,
          child: SvgPicture.asset(svgAsset, width: 20, height: 20),
        ),
      ),
    );
  }
}
