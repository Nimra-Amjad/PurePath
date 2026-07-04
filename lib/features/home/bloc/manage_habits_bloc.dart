import 'package:bloc/bloc.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/core/repositories/home_repository.dart';

part 'manage_habits_event.dart';
part 'manage_habits_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Manage habits BLoC
//
// Responsibilities:
//   • Load the full habits list from [HomeRepository]
//   • Handle delete and update operations
//   • Keep the displayed list in sync after each mutation
//
// Uses the same [HomeRepository] as [HomeBloc] — swapping in Firestore
// only requires changing one line in [ManageHabitsPage].
// ─────────────────────────────────────────────────────────────────────────────

class ManageHabitsBloc extends Bloc<ManageHabitsEvent, ManageHabitsState> {
  final HomeRepository _repository;

  ManageHabitsBloc({required HomeRepository repository})
    : _repository = repository,
      super(const ManageHabitsState(status: ManageHabitsStatus.loading)) {
    on<ManageHabitsStarted>(_onStarted);
    on<ManageHabitAddRequested>(_onAddRequested);
    on<ManageHabitDeleteRequested>(_onDeleteRequested);
    on<ManageHabitUpdateRequested>(_onUpdateRequested);
  }

  // ── Event handlers ────────────────────────────────────────────────────────

  /// Loads all habits from the repository.
  Future<void> _onStarted(
    ManageHabitsStarted event,
    Emitter<ManageHabitsState> emit,
  ) async {
    try {
      final habits = await _repository.getAllHabits();
      emit(state.copyWith(status: ManageHabitsStatus.loaded, habits: habits));
    } catch (e) {
      emit(
        state.copyWith(
          status: ManageHabitsStatus.error,
          errorMessage: 'Could not load habits. Please try again.',
        ),
      );
    }
  }

  /// Persists the new habit then re-fetches the list so the new id is included.
  Future<void> _onAddRequested(
    ManageHabitAddRequested event,
    Emitter<ManageHabitsState> emit,
  ) async {
    try {
      await _repository.addHabit(event.definition);
      final habits = await _repository.getAllHabits();
      emit(state.copyWith(status: ManageHabitsStatus.loaded, habits: habits));
    } catch (_) {
      // Non-fatal: the form can be re-submitted.
    }
  }

  /// Removes the habit from the repository then refreshes the list.
  Future<void> _onDeleteRequested(
    ManageHabitDeleteRequested event,
    Emitter<ManageHabitsState> emit,
  ) async {
    try {
      await _repository.deleteHabit(event.habitId);
      // Optimistically remove from the current list — no need for a full reload.
      final updated = state.habits.where((h) => h.id != event.habitId).toList();
      emit(state.copyWith(habits: updated));
    } catch (_) {
      // Non-fatal: the tile stays visible; the user can try again.
    }
  }

  /// Persists the edited habit and updates the list in place.
  Future<void> _onUpdateRequested(
    ManageHabitUpdateRequested event,
    Emitter<ManageHabitsState> emit,
  ) async {
    try {
      await _repository.updateHabit(event.definition);
      final updated = state.habits.map((h) {
        return h.id == event.definition.id ? event.definition : h;
      }).toList();
      emit(state.copyWith(habits: updated));
    } catch (_) {
      // Non-fatal: the form can be re-submitted.
    }
  }
}
