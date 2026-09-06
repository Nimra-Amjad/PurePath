import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Month calendar grid
//
// A Monday-first calendar for one month: a weekday header (M T W T F S S) then
// rows of square day cells, with leading blanks so day 1 lands under its real
// weekday. Each day's cell is supplied by [cellBuilder] so the same grid can
// render both the overall heatmap and each per-habit calendar.
//
// Cell size is derived from the available width via [LayoutBuilder] so every
// column is an exact square with no reliance on intrinsic/aspect sizing.
// ─────────────────────────────────────────────────────────────────────────────

class MonthCalendarGrid extends StatelessWidget {
  /// First day (midnight) of the month to render.
  final DateTime monthStart;

  /// Builds the cell for a given day. Return a [MonthDayCell] (or similar).
  final Widget Function(DateTime date, int day) cellBuilder;

  const MonthCalendarGrid({
    super.key,
    required this.monthStart,
    required this.cellBuilder,
  });

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const double _spacing = 5;

  int get _daysInMonth =>
      DateTime(monthStart.year, monthStart.month + 1, 0).day;

  /// Blank leading cells before day 1 (Mon = 0 … Sun = 6).
  int get _leadingBlanks => monthStart.weekday - 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth - _spacing * 6) / 7;

        final slots = <Widget?>[
          for (var i = 0; i < _leadingBlanks; i++) null,
          for (var day = 1; day <= _daysInMonth; day++)
            cellBuilder(DateTime(monthStart.year, monthStart.month, day), day),
        ];
        while (slots.length % 7 != 0) {
          slots.add(null);
        }

        Widget rowOf(List<Widget?> items, double height) => Row(
          children: [
            for (var c = 0; c < 7; c++) ...[
              if (c != 0) const SizedBox(width: _spacing),
              SizedBox(
                width: cell,
                height: height,
                child: items[c],
              ),
            ],
          ],
        );

        final weekRows = <Widget>[];
        for (var r = 0; r < slots.length; r += 7) {
          weekRows.add(
            Padding(
              padding: EdgeInsets.only(
                bottom: r + 7 < slots.length ? _spacing : 0,
              ),
              child: rowOf(slots.sublist(r, r + 7), cell),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekday header — same column geometry as the day rows.
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: rowOf(
                [
                  for (final letter in _letters)
                    Center(
                      child: Text(
                        letter,
                        style: AppTextStyles.medium.copyWith(
                          fontSize: 11,
                          color: kLightGreyColor,
                        ),
                      ),
                    ),
                ],
                16,
              ),
            ),
            ...weekRows,
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month day cell — a rounded square holding the day number.
//
// [fill] tints the square; [textColor] the number. An optional [border] outlines
// today and [glow] highlights a peak/perfect day.
// ─────────────────────────────────────────────────────────────────────────────

class MonthDayCell extends StatelessWidget {
  final int day;
  final Color fill;
  final Color textColor;
  final bool border;
  final bool glow;

  const MonthDayCell({
    super.key,
    required this.day,
    required this.fill,
    required this.textColor,
    this.border = false,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: border
            ? Border.all(color: kWhiteColor.withOpacityValue(0.9), width: 1.5)
            : null,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: kPrimaryGreenColor.withOpacityValue(0.55),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: AppTextStyles.medium.copyWith(fontSize: 12, color: textColor),
        ),
      ),
    );
  }
}
