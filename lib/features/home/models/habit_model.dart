import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit category
//
// Using an enum keeps colors and icons in one place.
// When you connect Firestore, store category as a string (e.g. "meditation")
// and use HabitCategory.fromString() to parse it back.
// ─────────────────────────────────────────────────────────────────────────────

enum HabitCategory { meditation, reading, hydration, fitness, journaling }

extension HabitCategoryExtension on HabitCategory {
  Color get color {
    switch (this) {
      case HabitCategory.meditation:
        return const Color(0xFF4CAF50); // green
      case HabitCategory.reading:
        return const Color(0xFF9C27B0); // purple
      case HabitCategory.hydration:
        return const Color(0xFF2196F3); // blue
      case HabitCategory.fitness:
        return const Color(0xFFFF9800); // orange
      case HabitCategory.journaling:
        return const Color(0xFFE91E63); // pink
    }
  }

  IconData get icon {
    switch (this) {
      case HabitCategory.meditation:
        return Icons.self_improvement;
      case HabitCategory.reading:
        return Icons.menu_book;
      case HabitCategory.hydration:
        return Icons.water_drop;
      case HabitCategory.fitness:
        return Icons.directions_run;
      case HabitCategory.journaling:
        return Icons.edit_note;
    }
  }

  /// Parse a Firestore string back to enum.
  static HabitCategory fromString(String value) {
    return HabitCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HabitCategory.meditation,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit model
//
// Represents one habit entry for a specific day.
// [progress] is 0.0 (not started) → 1.0 (fully completed).
// Used to:
//   • Determine [isCompleted] → shows the checkmark badge in the tile
//   • Feed DaySummary.overallProgress → drives the arc ring in the calendar
// ─────────────────────────────────────────────────────────────────────────────

class HabitModel {
  final String id;
  final String title;
  final String subtitle;
  final HabitCategory category;
  final double progress; // 0.0 – 1.0

  const HabitModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.progress,
  });

  bool get isCompleted => progress >= 1.0;
}
