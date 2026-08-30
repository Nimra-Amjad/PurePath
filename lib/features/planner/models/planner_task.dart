// ─────────────────────────────────────────────────────────────────────────────
// Planner task
//
// One user-created task pinned to a specific day + hour on the planner timeline.
//
// [date] is always stored at local midnight and identifies the day the task
// belongs to; [hour] (0–23) identifies which hourly slot it sits in. Together
// they drive where the task card renders on the vertical 12 AM → 11 PM timeline.
//
// Firestore: tasks are NOT stored one-per-doc. They live in a `tasks` array on
// the day document `planner/{uid}/days/{dd-MM-yyyy}`, so [date] is carried by
// the parent doc, not by each entry. [toEntry] / [fromEntry] handle that array
// element; see PlannerProvider for the full day-document schema.
// ─────────────────────────────────────────────────────────────────────────────

class PlannerTask {
  final String id;
  final String title;

  /// Optional free-text detail. Empty string when the user added none.
  final String note;

  /// The day the task belongs to (always local midnight).
  final DateTime date;

  /// The hourly slot the task sits in, 0 (12 AM) … 23 (11 PM).
  final int hour;

  /// Whether the user has checked the task off.
  final bool done;

  const PlannerTask({
    required this.id,
    required this.title,
    required this.date,
    required this.hour,
    this.note = '',
    this.done = false,
  });

  // ── copyWith ───────────────────────────────────────────────────────────────

  PlannerTask copyWith({
    String? id,
    String? title,
    String? note,
    DateTime? date,
    int? hour,
    bool? done,
  }) {
    return PlannerTask(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date ?? this.date,
      hour: hour ?? this.hour,
      done: done ?? this.done,
    );
  }

  // ── Serialization ──────────────────────────────────────────────────────────
  //
  // A task is one element of the day document's `tasks` array — the day (date)
  // lives on the parent doc, so it isn't repeated here.

  /// This task as an array entry on the day document.
  Map<String, dynamic> toEntry() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'hour': hour,
      'done': done,
    };
  }

  /// Rebuilds a task from a `tasks` array entry. [date] is the parent day
  /// document's date (local midnight), stamped onto every task it owns.
  factory PlannerTask.fromEntry(
    Map<String, dynamic> map, {
    required DateTime date,
  }) {
    // Clamp the stored hour into the valid 0–23 range so a corrupt value can
    // never throw when the timeline indexes by it.
    final rawHour = (map['hour'] as num?)?.toInt() ?? 0;
    return PlannerTask(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      note: map['note'] as String? ?? '',
      date: DateTime(date.year, date.month, date.day),
      hour: rawHour.clamp(0, 23),
      done: map['done'] as bool? ?? false,
    );
  }
}
