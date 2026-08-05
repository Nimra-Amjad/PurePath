import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/home/models/habit_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit collection card
//
// A single habit's completion history rendered as a dot grid (one dot = one
// day, oldest → newest, wrapping left-to-right). One fixed green palette is
// shared by every habit so the grids read the same everywhere:
//
//   • dark green  → completed that day
//   • light green → scheduled but missed
//   • grey         → habit wasn't running that day (not scheduled / didn't exist)
//
// Data comes from [InsightsState.completionHistory] (date → completed ids).
// The card is self-contained so the insights screen and the full collection
// page can both drop it in. [HabitCollectionLegend] explains the palette.
// ─────────────────────────────────────────────────────────────────────────────

class HabitCollectionCard extends StatelessWidget {
  // Fixed dot palette — identical for every habit.
  static const Color completedColor = Color(0xFF2E7D32); // dark green
  static const Color missedColor = Color.fromARGB(
    255,
    141,
    161,
    142,
  ); // light green
  static const Color offColor = Color(0xFF3A3A3C); // grey — not running

  final HabitDefinition habit;

  /// date (local midnight) → set of habit ids completed that day.
  final Map<DateTime, Set<String>> history;

  /// How many days back the grid covers (ending today).
  final int days;

  /// When false, the top-right frequency label is hidden — used for the
  /// insights preview so a "View All" overlay can sit in that corner instead.
  final bool showFrequency;

  const HabitCollectionCard({
    super.key,
    required this.habit,
    required this.history,
    this.days = 105,
    this.showFrequency = true,
  });

  static const double _dot = 13;
  static const double _gap = 5;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Whether the habit is scheduled to run on [date] (inside its active window
  /// and on a matching weekday for weekly habits).
  bool _isScheduled(DateTime date) {
    if (!habit.isActiveOn(date)) return false;
    if (habit.isDaily) return true;
    return habit.weekDays.contains(date.weekday - 1);
  }

  /// "Everyday" for daily habits, otherwise "N times a week".
  String get _frequencyLabel {
    if (habit.isDaily || habit.weekDays.length >= 7) return 'Everyday';
    final n = habit.weekDays.length;
    if (n <= 1) return '1 time a week';
    return '$n times a week';
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;

    // Oldest → newest so the most recent days land at the bottom-right.
    final dots = List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final scheduled = _isScheduled(date);
      final completed =
          scheduled && (history[date]?.contains(habit.id) ?? false);
      return _Dot(scheduled: scheduled, completed: completed);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: emoji + title  ···  frequency ─────────────────────────
          Row(
            children: [
              Text(habit.category.emoji, style: const TextStyle(fontSize: 18)),
              Space.horizontal(8),
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
              if (showFrequency) ...[
                Space.horizontal(8),
                Text(
                  _frequencyLabel,
                  style: AppTextStyles.normal.copyWith(
                    fontSize: 12,
                    color: kSecondaryGreyColor,
                  ),
                ),
              ],
            ],
          ),
          Space.vertical(14),

          // ── Dot grid ──────────────────────────────────────────────────────
          Wrap(spacing: _gap, runSpacing: _gap, children: dots),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One day cell.
// ─────────────────────────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  final bool scheduled;
  final bool completed;

  const _Dot({required this.scheduled, required this.completed});

  @override
  Widget build(BuildContext context) {
    final Color fill;
    if (completed) {
      fill = HabitCollectionCard.completedColor; // dark green — done
    } else if (scheduled) {
      fill = HabitCollectionCard.missedColor; // light green — missed
    } else {
      fill = HabitCollectionCard.offColor; // grey — not running that day
    }

    return Container(
      width: HabitCollectionCard._dot,
      height: HabitCollectionCard._dot,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit collection legend
//
// Explains the three dot colours. Sits once below the grids on the full
// collection page.
// ─────────────────────────────────────────────────────────────────────────────

class HabitCollectionLegend extends StatelessWidget {
  const HabitCollectionLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _LegendRow(
            color: HabitCollectionCard.completedColor,
            label: 'Completed',
          ),
          _LegendRow(color: HabitCollectionCard.missedColor, label: 'Missed'),
          _LegendRow(
            color: HabitCollectionCard.offColor,
            label: 'Not scheduled',
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Space.horizontal(10),
        Text(
          label,
          style: AppTextStyles.normal.copyWith(
            fontSize: 13,
            color: kWhiteColor,
          ),
        ),
      ],
    );
  }
}
