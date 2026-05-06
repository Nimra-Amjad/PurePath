part of 'manage_habits_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Manage habits events
// ─────────────────────────────────────────────────────────────────────────────

sealed class ManageHabitsEvent {}

/// Triggered once when the manage-habits screen opens.
final class ManageHabitsStarted extends ManageHabitsEvent {}

/// Triggered when the user creates a new habit on the add-habit screen.
final class ManageHabitAddRequested extends ManageHabitsEvent {
  final HabitDefinition definition;
  ManageHabitAddRequested(this.definition);
}

/// Triggered when the user confirms deletion of a habit.
final class ManageHabitDeleteRequested extends ManageHabitsEvent {
  final String habitId;
  ManageHabitDeleteRequested(this.habitId);
}

/// Triggered when the user saves changes in the edit form.
final class ManageHabitUpdateRequested extends ManageHabitsEvent {
  final HabitDefinition definition;
  ManageHabitUpdateRequested(this.definition);
}
