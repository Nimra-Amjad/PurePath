// ─────────────────────────────────────────────────────────────────────────────
// Hour label
//
// Formats a 0–23 timeline slot into a 12-hour clock label:
//   0 → "12 AM", 1 → "1 AM", 12 → "12 PM", 13 → "1 PM", 23 → "11 PM".
// Shared by the timeline rows and the add/edit task sheet so the two never
// drift apart.
// ─────────────────────────────────────────────────────────────────────────────

String plannerHourLabel(int hour) {
  final h = hour % 24;
  final period = h < 12 ? 'AM' : 'PM';
  final display = h % 12 == 0 ? 12 : h % 12;
  return '$display $period';
}
