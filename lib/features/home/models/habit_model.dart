// ─────────────────────────────────────────────────────────────────────────────
// Habit model
//
// Represents one habit entry for a specific day.
//
// [progress] is 0.0 (not started) → 1.0 (fully completed).
// It drives two things:
//   • [isCompleted] → shows the checkmark badge in the habit tile
//   • DaySummary.overallProgress → drives the arc ring in the calendar
//
// Habits no longer carry a category — every habit shares one accent color and
// emoji (see kHabitAccentColor / kHabitEmoji in color_constants.dart).
// ─────────────────────────────────────────────────────────────────────────────

class HabitModel {
  final String id;
  final String title;

  /// Short line under the title — a human-readable schedule summary,
  /// e.g. "Every day", "Mon, Wed, Fri", or "Day 1, 15".
  final String subtitle;

  final double progress; // 0.0 – 1.0

  /// Short frequency label shown on the tile badge:
  /// "Daily", "Weekly", or "Monthly".
  final String frequencyLabel;

  const HabitModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    this.frequencyLabel = 'Daily',
  });

  bool get isCompleted => progress >= 1.0;
}
