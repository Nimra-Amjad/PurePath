part of 'manage_habits_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Manage habits status
// ─────────────────────────────────────────────────────────────────────────────

enum ManageHabitsStatus { loading, loaded, error }

// ─────────────────────────────────────────────────────────────────────────────
// Manage habits state
// ─────────────────────────────────────────────────────────────────────────────

class ManageHabitsState {
  final ManageHabitsStatus status;
  final List<HabitDefinition> habits;
  final String? errorMessage;

  const ManageHabitsState({
    required this.status,
    this.habits = const [],
    this.errorMessage,
  });

  ManageHabitsState copyWith({
    ManageHabitsStatus? status,
    List<HabitDefinition>? habits,
    String? errorMessage,
  }) {
    return ManageHabitsState(
      status: status ?? this.status,
      habits: habits ?? this.habits,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
