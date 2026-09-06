import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/habit_definition.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit matrix card
//
//   Habit matrix            M  T  W  T  F  S  S
//   Walk                    ▪  ▪  ▪  ▪  ▪  ▪  ▪   ✓7
//   Yoga                    ▪  ▪  ·  ·  ▪  ▪  ▪   ✓5
//   …
//
// One row per habit. Each of the 7 cells (Mon → Sun of the visible week) is:
//   • filled with the habit's accent color → completed that day
//   • faint accent tint                    → scheduled but missed
//   • near-empty                            → not scheduled that day
//
// The trailing pill shows how many days the habit was completed this week
// (✓ N). (Streaks were removed from the app, so this is a plain weekly count.)
// ─────────────────────────────────────────────────────────────────────────────

class HabitMatrixCard extends StatelessWidget {
  final List<HabitDefinition> habits;

  /// date (local midnight) → set of habit ids completed that day.
  final Map<DateTime, Set<String>> history;

  /// Monday of the visible week.
  final DateTime weekStart;

  const HabitMatrixCard({
    super.key,
    required this.habits,
    required this.history,
    required this.weekStart,
  });

  static const double _cell = 18;
  static const double _gap = 5;
  static const double _pillWidth = 46;
  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  double get _gridWidth => _cell * 7 + _gap * 6;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: title + weekday letters ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Habit matrix',
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 16,
                    color: kWhiteColor,
                  ),
                ),
              ),
              SizedBox(
                width: _gridWidth,
                child: Row(
                  children: [
                    for (var i = 0; i < _letters.length; i++) ...[
                      if (i != 0) const SizedBox(width: _gap),
                      SizedBox(
                        width: _cell,
                        child: Text(
                          _letters[i],
                          textAlign: TextAlign.center,
                          style: AppTextStyles.medium.copyWith(
                            fontSize: 11,
                            color: kLightGreyColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: _gap + _pillWidth),
            ],
          ),
          Space.vertical(16),

          // ── One row per habit ──────────────────────────────────────────────
          for (var i = 0; i < habits.length; i++) ...[
            _HabitRow(
              habit: habits[i],
              history: history,
              weekStart: weekStart,
              cell: _cell,
              gap: _gap,
              gridWidth: _gridWidth,
              pillWidth: _pillWidth,
            ),
            if (i != habits.length - 1) Space.vertical(14),
          ],
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final HabitDefinition habit;
  final Map<DateTime, Set<String>> history;
  final DateTime weekStart;
  final double cell;
  final double gap;
  final double gridWidth;
  final double pillWidth;

  const _HabitRow({
    required this.habit,
    required this.history,
    required this.weekStart,
    required this.cell,
    required this.gap,
    required this.gridWidth,
    required this.pillWidth,
  });

  @override
  Widget build(BuildContext context) {
    final accent = habit.accentColor;

    // Build the 7 cells for Mon → Sun and count completed days.
    final cells = <Widget>[];
    var completedDays = 0;
    for (var i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final scheduled = habit.isActiveOn(date) && habit.runsOn(date);
      final completed =
          scheduled && (history[date]?.contains(habit.id) ?? false);
      if (completed) completedDays++;

      final Color fill;
      if (completed) {
        fill = accent;
      } else if (scheduled) {
        fill = accent.withOpacityValue(0.16);
      } else {
        fill = kWhiteColor.withOpacityValue(0.04);
      }

      if (i != 0) cells.add(SizedBox(width: gap));
      cells.add(
        Container(
          width: cell,
          height: cell,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            habit.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.medium.copyWith(
              fontSize: 15,
              color: kWhiteColor,
            ),
          ),
        ),
        SizedBox(width: gridWidth, child: Row(children: cells)),
        SizedBox(width: gap),
        SizedBox(
          width: pillWidth,
          child: _CountPill(count: completedDays, accent: accent),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Count pill — "✓ N" days completed this week.
// ─────────────────────────────────────────────────────────────────────────────

class _CountPill extends StatelessWidget {
  final int count;
  final Color accent;

  const _CountPill({required this.count, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kBlackColor.withOpacityValue(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 12, color: accent),
          Space.horizontal(3),
          Text(
            '$count',
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 12,
              color: kWhiteColor,
            ),
          ),
        ],
      ),
    );
  }
}
