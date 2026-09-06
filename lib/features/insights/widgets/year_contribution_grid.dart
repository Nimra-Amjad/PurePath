import 'package:flutter/material.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/features/home/models/habit_definition.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Year contribution grid
//
// A GitHub-style heatmap of one habit across a whole year: 7 rows (Mon → Sun),
// one column per week. Each cell is filled with the habit's accent color when
// completed, a faint accent when scheduled but not yet completed (including
// future days), and an empty tint when not scheduled at all.
//
// Cell size is derived from the available width so the full year always fits.
// ─────────────────────────────────────────────────────────────────────────────

class YearContributionGrid extends StatelessWidget {
  final HabitDefinition habit;

  /// date (local midnight) → set of habit ids completed that day.
  final Map<DateTime, Set<String>> history;

  final int year;

  const YearContributionGrid({
    super.key,
    required this.habit,
    required this.history,
    required this.year,
  });

  static const Color _empty = Color(0xFF1c1c1e);
  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    final accent = habit.accentColor;
    final start = DateTime(year, 1, 1);
    final leading = start.weekday - 1; // Mon = 0 … Sun = 6
    final daysInYear = DateTime(year, 12, 31).difference(start).inDays + 1;
    final totalSlots = leading + daysInYear;
    final cols = (totalSlots / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = ((constraints.maxWidth - _gap * (cols - 1)) / cols).clamp(
          1.0,
          14.0,
        );

        Widget cellFor(int col, int row) {
          final index = col * 7 + row - leading;
          if (index < 0 || index >= daysInYear) {
            return SizedBox(width: cell, height: cell);
          }
          final date = start.add(Duration(days: index));
          final completed = history[date]?.contains(habit.id) ?? false;
          final scheduled = habit.countsOn(date, completed: completed);

          final Color fill;
          if (completed) {
            fill = accent;
          } else if (scheduled) {
            fill = accent.withOpacityValue(0.15);
          } else {
            fill = _empty;
          }

          return Container(
            width: cell,
            height: cell,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < cols; c++) ...[
              if (c != 0) const SizedBox(width: _gap),
              Column(
                children: [
                  for (var r = 0; r < 7; r++) ...[
                    if (r != 0) const SizedBox(height: _gap),
                    cellFor(c, r),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
