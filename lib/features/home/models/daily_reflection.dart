import 'package:purepath/features/home/models/mood.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Daily reflection
//
// One day's journal entry: an optional [mood] and a free-text [note]. Both are
// optional on their own — a user might log only a mood, only a note, or both.
//
// Stored as two extra fields on the existing per-day insights doc
// (`insights/{uid}/days/{yyyymmdd}`) rather than in a separate collection, so a
// day's reflection lives right beside that day's habit completions:
//   { …, mood: "good", note: "Slept well, felt focused." }
// ─────────────────────────────────────────────────────────────────────────────

class DailyReflection {
  final Mood? mood;
  final String note;

  const DailyReflection({this.mood, this.note = ''});

  /// True when there's nothing worth showing — used by the card to decide
  /// between the "add reflection" prompt and the filled-in summary.
  bool get isEmpty => mood == null && note.trim().isEmpty;

  /// Reads the reflection fields off a raw day doc. Unknown / missing values
  /// degrade gracefully to "no mood" and an empty note.
  factory DailyReflection.fromMap(Map<String, dynamic> map) {
    return DailyReflection(
      mood: Mood.fromName(map['mood'] as String?),
      note: (map['note'] as String?)?.trim() ?? '',
    );
  }

  DailyReflection copyWith({Mood? mood, String? note, bool clearMood = false}) {
    return DailyReflection(
      mood: clearMood ? null : (mood ?? this.mood),
      note: note ?? this.note,
    );
  }
}
