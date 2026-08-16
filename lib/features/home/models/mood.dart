import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mood
//
// The five moods a user can log for a day, ordered worst → best. Each mood
// carries everything the UI needs to render it — an emoji, a short label, and
// an accent colour — so widgets never hard-code these anywhere. Persisted by
// [name] (e.g. "good") inside the day doc, which keeps the stored value stable
// even if the emoji or colour is later tweaked.
// ─────────────────────────────────────────────────────────────────────────────

enum Mood {
  rough(emoji: '😞', label: 'Rough', color: Color(0xFFEF4444)),
  low(emoji: '😕', label: 'Low', color: Color(0xFFF97316)),
  okay(emoji: '😐', label: 'Okay', color: Color(0xFFF5C518)),
  good(emoji: '🙂', label: 'Good', color: Color(0xFF8BC34A)),
  great(emoji: '😄', label: 'Great', color: Color(0xFFCFE36E));

  const Mood({required this.emoji, required this.label, required this.color});

  final String emoji;
  final String label;
  final Color color;

  /// Resolves a stored [name] back to a [Mood], or null when the value is
  /// missing / unrecognised (e.g. an older record or a future mood we don't
  /// know about yet). Kept tolerant so a bad value never crashes the day view.
  static Mood? fromName(String? name) {
    if (name == null) return null;
    for (final mood in Mood.values) {
      if (mood.name == name) return mood;
    }
    return null;
  }
}
