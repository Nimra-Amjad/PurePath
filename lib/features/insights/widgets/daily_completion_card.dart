import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/day_summary.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Daily completion card
//
//   Daily completion                         6 habits tracked
//   100%  67%  50%  83%  83%  83%  67%
//    ▮    ▮    ▮    ▮    ▮    ▮    ▮
//   MON  TUE  WED  THU  FRI  SAT  SUN
//
// One vertical bar per day (Mon → Sun). Bar height is that day's overall
// completion (0.0 → 1.0). Today is highlighted in the bright lime accent; the
// other days use a muted green.
// ─────────────────────────────────────────────────────────────────────────────

class DailyCompletionCard extends StatelessWidget {
  /// 7 [DaySummary] entries for the visible week, Mon → Sun.
  final List<DaySummary> summaries;

  /// Distinct habits scheduled during the week — the header count.
  final int trackedHabitCount;

  const DailyCompletionCard({
    super.key,
    required this.summaries,
    required this.trackedHabitCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Daily completion',
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 16,
                    color: kWhiteColor,
                  ),
                ),
              ),
              Text(
                '$trackedHabitCount habits tracked',
                style: AppTextStyles.normal.copyWith(
                  fontSize: 13,
                  color: kLightGreyColor,
                ),
              ),
            ],
          ),
          Space.vertical(18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in summaries)
                Expanded(child: _Bar(summary: day)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final DaySummary summary;

  const _Bar({required this.summary});

  bool get _isToday {
    final now = DateTime.now();
    return summary.date == DateTime(now.year, now.month, now.day);
  }

  static const double _trackHeight = 130;

  @override
  Widget build(BuildContext context) {
    final progress = summary.overallProgress;
    final dayLabel = DateFormat('EEE').format(summary.date).toUpperCase();
    final fillColor = _isToday
        ? kPrimaryGreenColor
        : kDarkGreenColor.withOpacityValue(0.75);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Percentage label above the bar (blank when nothing done).
        Text(
          progress > 0 ? '${(progress * 100).round()}%' : '',
          style: AppTextStyles.medium.copyWith(
            fontSize: 11,
            color: _isToday ? kPrimaryGreenColor : kLightGreyColor,
          ),
        ),
        Space.vertical(6),

        // Bar — a rounded track with a fill that grows up from the bottom.
        SizedBox(
          height: _trackHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(color: kBlackColor.withOpacityValue(0.25)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => FractionallySizedBox(
                      heightFactor: value,
                      child: child,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            fillColor.withOpacityValue(0.6),
                            fillColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Space.vertical(8),

        // Day label.
        Text(
          dayLabel,
          style: AppTextStyles.medium.copyWith(
            fontSize: 11,
            color: _isToday ? kPrimaryGreenColor : kLightGreyColor,
          ),
        ),
      ],
    );
  }
}
