part of 'daily_reflection_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Daily reflection state
//
// A single immutable cache of reflections keyed by date-only (midnight)
// DateTimes. A date present in [byDate] has been loaded; a date absent from it
// hasn't been fetched yet. The UI reads through [reflectionFor].
// ─────────────────────────────────────────────────────────────────────────────

class DailyReflectionState {
  /// Loaded reflections by date-only key. Absent = not yet fetched.
  final Map<DateTime, DailyReflection> byDate;

  const DailyReflectionState({this.byDate = const {}});

  /// The reflection cached for [date], or null while it's still loading.
  DailyReflection? reflectionFor(DateTime date) =>
      byDate[DateTime(date.year, date.month, date.day)];

  /// Returns a new state with [reflection] stored for [date], preserving every
  /// other cached day.
  DailyReflectionState withReflection(
    DateTime date,
    DailyReflection reflection,
  ) {
    return DailyReflectionState(byDate: {...byDate, date: reflection});
  }
}
