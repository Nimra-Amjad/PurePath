import 'package:purepath/features/home/models/habit_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Day summary
//
// Holds all habit data for a single calendar day.
// Computed properties (completedCount, totalCount, overallProgress) are derived
// from the habits list — no need to store them separately.
// ─────────────────────────────────────────────────────────────────────────────

class DaySummary {
  final DateTime date;
  final List<HabitModel> habits;

  const DaySummary({
    required this.date,
    required this.habits,
  });

  /// Number of habits the user has fully completed today.
  int get completedCount => habits.where((h) => h.isCompleted).length;

  /// Total number of habits scheduled for today.
  int get totalCount => habits.length;

  /// Overall completion ratio (0.0 → 1.0). Used to draw the arc in the calendar.
  double get overallProgress =>
      totalCount == 0 ? 0.0 : completedCount / totalCount;
}
