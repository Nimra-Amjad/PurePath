import 'package:flutter/material.dart';
import 'package:purepath/core/constants/color_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit type
//
// Distinguishes habits the user built themselves from ones they added out of
// the app's predefined habit library (Explore).
//
// Firestore: stored as the `type` field (HabitType.name). Parse it back with
// HabitTypeExtension.fromString().
// ─────────────────────────────────────────────────────────────────────────────

enum HabitType {
  /// Created by the user via the "New Habit" screen.
  custom,

  /// Added from the app's predefined habit library.
  predefined,
}

extension HabitTypeExtension on HabitType {
  /// Parses a stored Firestore string back into a [HabitType].
  /// Falls back to [HabitType.custom] for unknown / missing values.
  static HabitType fromString(String? value) {
    return HabitType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HabitType.custom,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit schedule
//
// How often a habit runs. This single field replaces the old `isDaily` boolean
// so the schedule is obvious at a glance — anyone reading the database can tell
// the mode from one value instead of inferring it from a bool + a list.
//
//   everyDay   → runs every single day.            (weekDays & monthDays unused)
//   weekDays   → runs on specific days of the week. (uses `weekDays`:  0=Mon…6=Sun)
//   monthDays  → runs on specific dates of the month.(uses `monthDays`: 1…31)
//
// Firestore: stored as the `scheduleType` field (HabitSchedule.name).
// ─────────────────────────────────────────────────────────────────────────────

enum HabitSchedule { everyDay, weekDays, monthDays }

extension HabitScheduleExtension on HabitSchedule {
  /// Parses a stored `scheduleType` string back into a [HabitSchedule].
  /// Falls back to [HabitSchedule.everyDay] for unknown / missing values.
  static HabitSchedule fromString(String? value) {
    return HabitSchedule.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HabitSchedule.everyDay,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit definition
//
// Represents the *configuration* of a habit — what the user set up when they
// tapped "Save". This is distinct from [HabitModel], which represents the
// habit's completion status for a specific calendar day.
//
// Firestore document shape (collection: `habits/{uid}/habits`):
//   {
//     id:              String
//     title:           String
//     type:            String   (HabitType.name — custom | predefined)
//     scheduleType:    String   (HabitSchedule.name — everyDay | weekDays | monthDays)
//     weekDays:        [int]    (0=Mon…6=Sun; used when scheduleType == weekDays)
//     monthDays:       [int]    (1…31;        used when scheduleType == monthDays)
//     reminderEnabled: bool     (whether a reminder notification is set)
//     reminderTime:    String   (e.g. "7:30 AM"; empty when no reminder)
//     startDateMillis: int      (local-midnight millis — first active day)
//     endDateMillis:   int?     (local-midnight millis — last active day, or null)
//   }
//     colorValue:      int?     (chosen accent color as ARGB; null = default)
// ─────────────────────────────────────────────────────────────────────────────

class HabitDefinition {
  final String id;
  final String title;

  /// Whether this habit was created by the user ([HabitType.custom]) or added
  /// from the app's predefined library ([HabitType.predefined]).
  final HabitType type;

  /// How often the habit runs — see [HabitSchedule].
  final HabitSchedule schedule;

  /// Indices of active weekdays (0 = Mon … 6 = Sun).
  /// Only meaningful when [schedule] is [HabitSchedule.weekDays].
  final List<int> weekDays;

  /// Active dates of the month (1 … 31).
  /// Only meaningful when [schedule] is [HabitSchedule.monthDays].
  final List<int> monthDays;

  /// Whether a reminder notification is set for this habit.
  final bool reminderEnabled;

  /// Formatted reminder time string, e.g. "7:30 AM". Empty = no reminder.
  final String reminderTime;

  /// First date the habit is active (always stored at local midnight).
  /// Defaults to the date the habit was created.
  final DateTime startDate;

  /// Last date the habit is active (inclusive). Null means "no end" — the
  /// habit shows up indefinitely from [startDate] onward.
  final DateTime? endDate;

  /// The habit's chosen accent color as an ARGB int. Null means the user didn't
  /// pick one, so [accentColor] falls back to [kHabitAccentColor].
  final int? colorValue;

  const HabitDefinition({
    required this.id,
    required this.title,
    required this.schedule,
    required this.startDate,
    this.type = HabitType.custom,
    this.endDate,
    this.weekDays = const [],
    this.monthDays = const [],
    this.reminderEnabled = false,
    this.reminderTime = '',
    this.colorValue,
  });

  /// The color to tint this habit with everywhere it's shown. Falls back to the
  /// shared default accent when the user hasn't chosen a custom color.
  Color get accentColor =>
      colorValue != null ? Color(colorValue!) : kHabitAccentColor;

  // ── Derived helpers ────────────────────────────────────────────────────────

  /// Convenience: true when the habit runs every day.
  bool get isEveryDay => schedule == HabitSchedule.everyDay;

  /// Short frequency label for badges: "Daily", "Weekly", or "Monthly".
  String get frequencyLabel {
    switch (schedule) {
      case HabitSchedule.everyDay:
        return 'Daily';
      case HabitSchedule.weekDays:
        return 'Weekly';
      case HabitSchedule.monthDays:
        return 'Monthly';
    }
  }

  /// Human-readable schedule summary shown under the title, e.g.
  /// "Every day", "Mon, Wed, Fri", or "Day 1, 15".
  String get subtitle {
    switch (schedule) {
      case HabitSchedule.everyDay:
        return 'Every day';
      case HabitSchedule.weekDays:
        if (weekDays.isEmpty) return 'Weekly';
        const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final sorted = [...weekDays]..sort();
        return sorted.map((i) => names[i]).join(', ');
      case HabitSchedule.monthDays:
        if (monthDays.isEmpty) return 'Monthly';
        final sorted = [...monthDays]..sort();
        return 'Day ${sorted.join(', ')}';
    }
  }

  /// Whether the habit is scheduled to run on [date] based on its [schedule]
  /// (ignores the active-window check — combine with [isActiveOn] for that).
  bool runsOn(DateTime date) {
    switch (schedule) {
      case HabitSchedule.everyDay:
        return true;
      case HabitSchedule.weekDays:
        return weekDays.contains(date.weekday - 1); // 0 = Mon … 6 = Sun
      case HabitSchedule.monthDays:
        return monthDays.contains(date.day);
    }
  }

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

  /// Whether [date] should count as scheduled for this habit — either the
  /// *current* schedule covers it, or [completed] is true (the habit was
  /// already marked done on that date). A later schedule edit — e.g. dropping
  /// a month-day the user already completed — shouldn't erase that day from
  /// history: the completion itself is the evidence it was scheduled at the
  /// time, even if [runsOn] no longer agrees.
  bool countsOn(DateTime date, {required bool completed}) =>
      completed || (isActiveOn(date) && runsOn(date));

  // ── copyWith ───────────────────────────────────────────────────────────────

  HabitDefinition copyWith({
    String? id,
    String? title,
    HabitType? type,
    HabitSchedule? schedule,
    List<int>? weekDays,
    List<int>? monthDays,
    bool? reminderEnabled,
    String? reminderTime,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    int? colorValue,
    bool clearColor = false,
  }) {
    return HabitDefinition(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      schedule: schedule ?? this.schedule,
      weekDays: weekDays ?? this.weekDays,
      monthDays: monthDays ?? this.monthDays,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      colorValue: clearColor ? null : (colorValue ?? this.colorValue),
    );
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'scheduleType': schedule.name,
      'weekDays': weekDays,
      'monthDays': monthDays,
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime,
      'startDateMillis': startDate.millisecondsSinceEpoch,
      'endDateMillis': endDate?.millisecondsSinceEpoch,
      'colorValue': colorValue,
    };
  }

  factory HabitDefinition.fromMap(Map<String, dynamic> map) {
    final startMillis = (map['startDateMillis'] as num?)?.toInt();
    final endMillis = (map['endDateMillis'] as num?)?.toInt();
    final start = startMillis != null
        ? _dateOnly(DateTime.fromMillisecondsSinceEpoch(startMillis))
        : _today();

    final reminderTime = map['reminderTime'] as String? ?? '';

    return HabitDefinition(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      type: HabitTypeExtension.fromString(map['type'] as String?),
      schedule: _scheduleFromMap(map),
      weekDays:
          (map['weekDays'] as List?)?.map((e) => (e as num).toInt()).toList() ??
              const [],
      monthDays:
          (map['monthDays'] as List?)?.map((e) => (e as num).toInt()).toList() ??
              const [],
      // Older docs had no explicit toggle — treat any saved time as enabled.
      reminderEnabled:
          map['reminderEnabled'] as bool? ?? reminderTime.trim().isNotEmpty,
      reminderTime: reminderTime,
      startDate: start,
      endDate: endMillis != null
          ? _dateOnly(DateTime.fromMillisecondsSinceEpoch(endMillis))
          : null,
      colorValue: (map['colorValue'] as num?)?.toInt(),
    );
  }

  /// Reads the schedule from a stored doc, staying backward-compatible with the
  /// old `isDaily` boolean (true → everyDay, false → weekDays).
  static HabitSchedule _scheduleFromMap(Map<String, dynamic> map) {
    final raw = map['scheduleType'] as String?;
    if (raw != null) return HabitScheduleExtension.fromString(raw);
    final isDaily = map['isDaily'] as bool?;
    if (isDaily != null) {
      return isDaily ? HabitSchedule.everyDay : HabitSchedule.weekDays;
    }
    return HabitSchedule.everyDay;
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
