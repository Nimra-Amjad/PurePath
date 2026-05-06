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

  /// First date the habit is active (always stored at local midnight).
  /// Defaults to the date the habit was created.
  final DateTime startDate;

  /// Last date the habit is active (inclusive). Null means "no end" — the
  /// habit shows up indefinitely from [startDate] onward.
  final DateTime? endDate;

  const HabitDefinition({
    required this.id,
    required this.title,
    required this.category,
    required this.isDaily,
    required this.startDate,
    this.endDate,
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

  /// True when [date] falls inside the habit's active window
  /// (between [startDate] and [endDate], inclusive). [endDate] = null means
  /// the habit is open-ended.
  bool isActiveOn(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    if (d.isBefore(start)) return false;
    final end = endDate;
    if (end != null) {
      final last = DateTime(end.year, end.month, end.day);
      if (d.isAfter(last)) return false;
    }
    return true;
  }

  // ── copyWith ───────────────────────────────────────────────────────────────

  HabitDefinition copyWith({
    String? id,
    String? title,
    HabitCategory? category,
    bool? isDaily,
    List<int>? weekDays,
    String? goal,
    String? reminderTime,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return HabitDefinition(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      isDaily: isDaily ?? this.isDaily,
      weekDays: weekDays ?? this.weekDays,
      goal: goal ?? this.goal,
      reminderTime: reminderTime ?? this.reminderTime,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'isDaily': isDaily,
      'weekDays': weekDays,
      'goal': goal,
      'reminderTime': reminderTime,
      'startDateMillis': startDate.millisecondsSinceEpoch,
      'endDateMillis': endDate?.millisecondsSinceEpoch,
    };
  }

  factory HabitDefinition.fromMap(Map<String, dynamic> map) {
    final startMillis = (map['startDateMillis'] as num?)?.toInt();
    final endMillis = (map['endDateMillis'] as num?)?.toInt();
    final start = startMillis != null
        ? _dateOnly(DateTime.fromMillisecondsSinceEpoch(startMillis))
        : _today();
    return HabitDefinition(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      category: HabitCategoryExtension.fromString(
        map['category'] as String? ?? '',
      ),
      isDaily: map['isDaily'] as bool? ?? true,
      weekDays:
          (map['weekDays'] as List?)?.map((e) => (e as num).toInt()).toList() ??
              const [],
      goal: map['goal'] as String? ?? '',
      reminderTime: map['reminderTime'] as String? ?? '',
      startDate: start,
      endDate: endMillis != null
          ? _dateOnly(DateTime.fromMillisecondsSinceEpoch(endMillis))
          : null,
    );
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
