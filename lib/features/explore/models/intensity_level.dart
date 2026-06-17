import 'package:flutter/material.dart';
import 'package:purepath/core/constants/color_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Intensity level
//
// Difficulty tier a suggested habit belongs to. Used by the Habit Library
// screen to group each category's habits into beginner / intermediate /
// advanced sections.
// ─────────────────────────────────────────────────────────────────────────────

enum IntensityLevel { beginner, intermediate, advanced }

extension IntensityLevelExtension on IntensityLevel {
  String get label {
    switch (this) {
      case IntensityLevel.beginner:     return 'Beginner';
      case IntensityLevel.intermediate: return 'Intermediate';
      case IntensityLevel.advanced:     return 'Advanced';
    }
  }

  /// One-line description shown under each section header.
  String get description {
    switch (this) {
      case IntensityLevel.beginner:
        return 'Easy wins to get started';
      case IntensityLevel.intermediate:
        return 'Build consistency and momentum';
      case IntensityLevel.advanced:
        return 'Push your limits and master it';
    }
  }

  /// Accent color used for the section badge and divider.
  Color get color {
    switch (this) {
      case IntensityLevel.beginner:     return kPrimaryGreenColor; // Lime
      case IntensityLevel.intermediate: return const Color(0xFFFFB300); // Amber
      case IntensityLevel.advanced:     return const Color(0xFFEF5350); // Coral
    }
  }

  IconData get icon {
    switch (this) {
      case IntensityLevel.beginner:     return Icons.spa_rounded;
      case IntensityLevel.intermediate: return Icons.trending_up_rounded;
      case IntensityLevel.advanced:     return Icons.local_fire_department_rounded;
    }
  }
}
