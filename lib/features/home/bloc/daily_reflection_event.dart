part of 'daily_reflection_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Daily reflection events
//
// sealed = exhaustive — the compiler flags any handler you forget to add.
// ─────────────────────────────────────────────────────────────────────────────

sealed class DailyReflectionEvent {}

/// Requests the reflection for [date]. A no-op when the day is already cached,
/// so the home page can fire this freely on every day selection.
final class ReflectionRequested extends DailyReflectionEvent {
  final DateTime date;
  ReflectionRequested(this.date);
}

/// Saves the mood + note the user entered for [date] in the reflection sheet.
final class ReflectionSaved extends DailyReflectionEvent {
  final DateTime date;
  final DailyReflection reflection;
  ReflectionSaved({required this.date, required this.reflection});
}
