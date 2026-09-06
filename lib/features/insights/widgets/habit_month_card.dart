import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/insights/widgets/month_calendar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit month card
//
//   Walk                       [ PERFECT ]  100%  30d
//   M  T  W  T  F  S  S
//   … month calendar tinted with the habit's accent color …
//
// Each day is filled with the habit's accent when completed, a faint accent when
// scheduled but not yet completed (including future days), and empty when not
// scheduled at all.
// ─────────────────────────────────────────────────────────────────────────────

class HabitMonthCard extends StatelessWidget {
  final HabitMonthStat stat;

  /// date (local midnight) → set of habit ids completed that day.
  final Map<DateTime, Set<String>> history;

  final DateTime monthStart;

  const HabitMonthCard({
    super.key,
    required this.stat,
    required this.history,
    required this.monthStart,
  });

  static const Color _empty = Color(0xFF242426);

  @override
  Widget build(BuildContext context) {
    final habit = stat.habit;
    final accent = habit.accentColor;
    final percent = (stat.progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 16,
                    color: kWhiteColor,
                  ),
                ),
              ),
              if (stat.isPerfect) ...[
                _PerfectBadge(accent: accent),
                Space.horizontal(10),
              ],
              Text(
                '$percent%',
                style: AppTextStyles.bold.copyWith(
                  fontSize: 15,
                  color: accent,
                ),
              ),
              Space.horizontal(8),
              Text(
                '${stat.scheduled}d',
                style: AppTextStyles.normal.copyWith(
                  fontSize: 13,
                  color: kLightGreyColor,
                ),
              ),
            ],
          ),
          Space.vertical(18),

          // ── Calendar ───────────────────────────────────────────────────────
          MonthCalendarGrid(
            monthStart: monthStart,
            cellBuilder: (date, day) {
              final scheduled = habit.isActiveOn(date) && habit.runsOn(date);
              final completed =
                  scheduled && (history[date]?.contains(habit.id) ?? false);

              final Color fill;
              final Color textColor;
              if (completed) {
                fill = accent;
                textColor = kBlackColor.withOpacityValue(0.75);
              } else if (scheduled) {
                fill = accent.withOpacityValue(0.16);
                textColor = kWhiteColor.withOpacityValue(0.7);
              } else {
                fill = _empty;
                textColor = kWhiteColor.withOpacityValue(0.25);
              }

              return MonthDayCell(
                day: day,
                fill: fill,
                textColor: textColor,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "PERFECT" badge — outlined pill in the habit's accent color.
// ─────────────────────────────────────────────────────────────────────────────

class _PerfectBadge extends StatelessWidget {
  final Color accent;

  const _PerfectBadge({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacityValue(0.6)),
      ),
      child: Text(
        'PERFECT',
        style: AppTextStyles.bold.copyWith(
          fontSize: 10,
          letterSpacing: 0.8,
          color: accent,
        ),
      ),
    );
  }
}
