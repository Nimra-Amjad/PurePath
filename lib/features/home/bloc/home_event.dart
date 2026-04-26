part of 'home_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home events
//
// sealed = exhaustive — the compiler tells you if you forget a case.
// ─────────────────────────────────────────────────────────────────────────────

sealed class HomeEvent {}

/// Triggered once when the home screen first opens.
/// The bloc loads data for the current week and selects today.
final class HomeStarted extends HomeEvent {}

/// Triggered when the user taps a day tile in the calendar.
final class HomeDateSelected extends HomeEvent {
  final DateTime date;
  HomeDateSelected(this.date);
}

/// Triggered when the user swipes to a different week.
/// [weekStart] is always the Monday of the newly visible week.
final class HomeWeekChanged extends HomeEvent {
  final DateTime weekStart;
  HomeWeekChanged(this.weekStart);
}

/// Triggered when the user taps a habit tile.
/// Toggles the habit between completed (1.0) and not started (0.0).
/// The calendar arc and progress card update automatically from the new state.
final class HabitToggled extends HomeEvent {
  final String habitId;
  HabitToggled(this.habitId);
}
