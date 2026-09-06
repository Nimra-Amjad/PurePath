import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit goal
//
// A goal the user might want to work towards (e.g. "Lose weight"), with a
// curated set of [HabitIdea]s that support it. Powers the "Habit ideas" grid
// and its per-goal "More habits" detail page.
// ─────────────────────────────────────────────────────────────────────────────

class HabitIdea {
  final String title;
  final IconData icon;

  const HabitIdea({required this.title, required this.icon});
}

class HabitGoal {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<HabitIdea> habits;

  const HabitGoal({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.habits,
  });
}
