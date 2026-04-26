import 'package:bloc/bloc.dart';
import 'package:purepath/features/home/models/day_summary.dart';
import 'package:purepath/features/home/models/habit_model.dart';
import 'package:purepath/features/home/repositories/home_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home BLoC
//
// Responsibilities:
//   • Load habit data for a week from [HomeRepository]
//   • Track which date is selected
//   • Cache already-loaded weeks (no redundant fetches)
//
// The bloc knows nothing about Flutter widgets — it only works with
// plain Dart objects (DateTime, DaySummary, HomeState).
// ─────────────────────────────────────────────────────────────────────────────

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _repository;

  HomeBloc({required HomeRepository repository})
    : _repository = repository,
      super(
        HomeState(
          status: HomeStatus.loading,
          selectedDate: _today,
          visibleWeekStart: _mondayOf(_today),
          weekData: const {},
        ),
      ) {
    on<HomeStarted>(_onStarted);
    on<HomeDateSelected>(_onDateSelected);
    on<HomeWeekChanged>(_onWeekChanged);
    on<HabitToggled>(_onHabitToggled);
  }

  // ── Static helpers (no widget dependencies) ───────────────────────────────

  /// Today's date with time stripped (always midnight).
  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Returns the Monday of the week that contains [date].
  static DateTime _mondayOf(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // ── Event handlers ────────────────────────────────────────────────────────

  /// Called once when the home screen opens.
  /// Loads data for the current week.
  Future<void> _onStarted(
    HomeStarted event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final weekData = await _repository.getSummaryForWeek(
        state.visibleWeekStart,
      );
      emit(state.copyWith(status: HomeStatus.loaded, weekData: weekData));
    } catch (e) {
      emit(
        state.copyWith(
          status: HomeStatus.error,
          errorMessage: 'Could not load habits. Please try again.',
        ),
      );
    }
  }

  /// Selecting a date is instant — no network call needed.
  /// Just update [selectedDate] in state.
  void _onDateSelected(HomeDateSelected event, Emitter<HomeState> emit) {
    emit(state.copyWith(selectedDate: event.date));
  }

  /// Called when the user swipes to a different week in the calendar.
  /// Updates [visibleWeekStart] immediately (so the month label updates),
  /// then fetches the week's data if not already cached.
  Future<void> _onWeekChanged(
    HomeWeekChanged event,
    Emitter<HomeState> emit,
  ) async {
    // Update the visible week right away (month label in header updates instantly).
    emit(state.copyWith(visibleWeekStart: event.weekStart));

    // Skip the fetch if all 7 days of this week are already in cache.
    if (_isWeekCached(event.weekStart)) return;

    try {
      final newWeekData = await _repository.getSummaryForWeek(event.weekStart);

      // Merge new data into the existing cache (preserves previously loaded weeks).
      emit(state.copyWith(weekData: {...state.weekData, ...newWeekData}));
    } catch (_) {
      // Non-fatal: the calendar shows empty arcs for uncached days.
      // The user can swipe back and the current week is unaffected.
    }
  }

  /// Called when the user taps a habit tile.
  ///
  /// Toggles the habit's progress between 1.0 (done) and 0.0 (not done),
  /// then writes the updated [DaySummary] back into [weekData].
  ///
  /// Because [weekData] is the single source of truth, both the calendar arc
  /// and the daily progress card automatically reflect the new values —
  /// no extra wiring needed.
  void _onHabitToggled(HabitToggled event, Emitter<HomeState> emit) {
    final summary = state.selectedDaySummary;
    if (summary == null) return;

    // Toggle: completed → 0.0 (undo), incomplete → 1.0 (mark done).
    final updatedHabits = summary.habits.map((habit) {
      if (habit.id != event.habitId) return habit;
      return HabitModel(
        id: habit.id,
        title: habit.title,
        subtitle: habit.subtitle,
        category: habit.category,
        progress: habit.isCompleted ? 0.0 : 1.0,
      );
    }).toList();

    final updatedSummary = DaySummary(
      date: summary.date,
      habits: updatedHabits,
    );

    emit(
      state.copyWith(
        weekData: {...state.weekData, state.selectedDate: updatedSummary},
      ),
    );
  }

  // ── Cache helpers ─────────────────────────────────────────────────────────

  /// Returns true if all 7 days of the given week are already in [weekData].
  bool _isWeekCached(DateTime weekStart) {
    return List.generate(7, (i) => weekStart.add(Duration(days: i))).every(
      (date) => state.weekData.containsKey(date),
    );
  }
}
