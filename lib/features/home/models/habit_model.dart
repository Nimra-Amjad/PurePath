import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit category
//
// Each category owns its emoji and color — no separate icon picker or color
// picker needed anywhere in the UI.
//
// Firestore tip: store `category.name` as a string field.
// Parse it back with HabitCategoryExtension.fromString().
// ─────────────────────────────────────────────────────────────────────────────

enum HabitCategory {
  fitness,
  nutrition,
  hydration,
  sleep,
  mindfulness,
  mentalHealth,
  learning,
  finance,
  selfCare,
  creativity,
  social,
  career,
  spirituality,
  digitalDetox,
  home,
}

extension HabitCategoryExtension on HabitCategory {
  // ── Display name ───────────────────────────────────────────────────────────

  String get label {
    switch (this) {
      case HabitCategory.fitness:       return 'Fitness';
      case HabitCategory.nutrition:     return 'Nutrition';
      case HabitCategory.hydration:     return 'Hydration';
      case HabitCategory.sleep:         return 'Sleep';
      case HabitCategory.mindfulness:   return 'Mindfulness';
      case HabitCategory.mentalHealth:  return 'Mental Health';
      case HabitCategory.learning:      return 'Learning';
      case HabitCategory.finance:       return 'Finance';
      case HabitCategory.selfCare:      return 'Self-Care';
      case HabitCategory.creativity:    return 'Creativity';
      case HabitCategory.social:        return 'Social';
      case HabitCategory.career:        return 'Career';
      case HabitCategory.spirituality:  return 'Spirituality';
      case HabitCategory.digitalDetox:  return 'Digital Detox';
      case HabitCategory.home:          return 'Home';
    }
  }

  // ── Emoji ──────────────────────────────────────────────────────────────────

  String get emoji {
    switch (this) {
      case HabitCategory.fitness:       return '🏃';
      case HabitCategory.nutrition:     return '🥗';
      case HabitCategory.hydration:     return '💧';
      case HabitCategory.sleep:         return '😴';
      case HabitCategory.mindfulness:   return '🧘';
      case HabitCategory.mentalHealth:  return '🧠';
      case HabitCategory.learning:      return '📖';
      case HabitCategory.finance:       return '💰';
      case HabitCategory.selfCare:      return '✨';
      case HabitCategory.creativity:    return '🎨';
      case HabitCategory.social:        return '🤝';
      case HabitCategory.career:        return '💼';
      case HabitCategory.spirituality:  return '🙏';
      case HabitCategory.digitalDetox:  return '📵';
      case HabitCategory.home:          return '🏠';
    }
  }

  // ── Color ──────────────────────────────────────────────────────────────────

  Color get color {
    switch (this) {
      case HabitCategory.fitness:       return const Color(0xFF9B82E8); // Purple
      case HabitCategory.nutrition:     return const Color(0xFF4CAF50); // Green
      case HabitCategory.hydration:     return const Color(0xFF29B6F6); // Sky Blue
      case HabitCategory.sleep:         return const Color(0xFF5C6BC0); // Indigo
      case HabitCategory.mindfulness:   return const Color(0xFFEF5350); // Coral Red
      case HabitCategory.mentalHealth:  return const Color(0xFF26A69A); // Mint Green
      case HabitCategory.learning:      return const Color(0xFF1E88E5); // Ocean Blue
      case HabitCategory.finance:       return const Color(0xFFFFB300); // Amber
      case HabitCategory.selfCare:      return const Color(0xFFEC407A); // Pink
      case HabitCategory.creativity:    return const Color(0xFFFDD835); // Yellow
      case HabitCategory.social:        return const Color(0xFF00897B); // Teal
      case HabitCategory.career:        return const Color(0xFFFB8C00); // Orange
      case HabitCategory.spirituality:  return const Color(0xFFAB47BC); // Mauve
      case HabitCategory.digitalDetox:  return const Color(0xFF546E7A); // Steel Blue
      case HabitCategory.home:          return const Color(0xFFD84315); // Terracotta
    }
  }

  // ── Firestore helpers ──────────────────────────────────────────────────────

  /// Parses a stored Firestore string back into a [HabitCategory].
  /// Falls back to [HabitCategory.fitness] for unknown values.
  static HabitCategory fromString(String value) {
    return HabitCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HabitCategory.fitness,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit model
//
// Represents one habit entry for a specific day.
//
// [progress] is 0.0 (not started) → 1.0 (fully completed).
// It drives two things:
//   • [isCompleted] → shows the checkmark badge in the habit tile
//   • DaySummary.overallProgress → drives the arc ring in the calendar
// ─────────────────────────────────────────────────────────────────────────────

class HabitModel {
  final String id;
  final String title;
  final String subtitle;
  final HabitCategory category;
  final double progress; // 0.0 – 1.0

  /// true → runs every day, false → runs on specific weekdays only.
  /// Used to show the Daily / Weekly badge on the habit tile.
  final bool isDaily;

  const HabitModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.progress,
    this.isDaily = true,
  });

  bool get isCompleted => progress >= 1.0;

  String get frequencyLabel => isDaily ? 'Daily' : 'Weekly';
}
