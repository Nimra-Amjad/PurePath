import 'package:purepath/features/home/models/habit_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit definition
//
// Represents the *configuration* of a habit — what the user set up when they
// tapped "Create Habit". This is distinct from [HabitModel], which represents
// the habit's completion status for a specific calendar day.
//
// Firestore tip: store each [HabitDefinition] as a document in the user's
// `habits` sub-collection.
// ─────────────────────────────────────────────────────────────────────────────

class HabitDefinition {
  final String id;
  final String title;
  final HabitCategory category;

  /// true  → habit runs every day
  /// false → habit runs only on [weekDays]
  final bool isDaily;

  /// Indices of active days (0 = Mon … 6 = Sun).
  /// Empty when [isDaily] is true.
  final List<int> weekDays;

  /// User-supplied goal description, e.g. "5 km". Empty = no goal.
  final String goal;

  /// Formatted reminder time string, e.g. "7:30 AM". Empty = no reminder.
  final String reminderTime;

  const HabitDefinition({
    required this.id,
    required this.title,
    required this.category,
    required this.isDaily,
    this.weekDays = const [],
    this.goal = '',
    this.reminderTime = '',
  });

  // ── Derived helpers ────────────────────────────────────────────────────────

  /// Short subtitle shown in tile and daily view.
  /// Uses the goal when set, otherwise falls back to the category label.
  String get subtitle =>
      goal.isNotEmpty ? '$goal · ${category.label}' : category.label;

  /// Human-readable frequency label.
  String get frequencyLabel => isDaily ? 'Daily' : 'Weekly';

  // ── copyWith ───────────────────────────────────────────────────────────────

  HabitDefinition copyWith({
    String? id,
    String? title,
    HabitCategory? category,
    bool? isDaily,
    List<int>? weekDays,
    String? goal,
    String? reminderTime,
  }) {
    return HabitDefinition(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      isDaily: isDaily ?? this.isDaily,
      weekDays: weekDays ?? this.weekDays,
      goal: goal ?? this.goal,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}
