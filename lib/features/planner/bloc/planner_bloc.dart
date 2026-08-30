import 'package:bloc/bloc.dart';
import 'package:purepath/core/repositories/planner_repository.dart';
import 'package:purepath/features/planner/models/planner_task.dart';

part 'planner_event.dart';
part 'planner_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Planner BLoC
//
// Responsibilities:
//   • Load the tasks for a selected day from [PlannerRepository]
//   • Track the selected date + visible week (drives the calendar)
//   • Add / edit / delete / toggle tasks and keep the day in sync
//   • Cache already-loaded days so re-selecting a day is instant
//
// The bloc knows nothing about Flutter widgets — it only works with plain Dart
// objects (DateTime, PlannerTask, PlannerState).
// ─────────────────────────────────────────────────────────────────────────────

class PlannerBloc extends Bloc<PlannerEvent, PlannerState> {
  final PlannerRepository _repository;

  PlannerBloc({required PlannerRepository repository})
    : _repository = repository,
      super(
        PlannerState(
          status: PlannerStatus.loading,
          selectedDate: _today,
          visibleWeekStart: _mondayOf(_today),
          tasksByDate: const {},
        ),
      ) {
    on<PlannerStarted>(_onStarted);
    on<PlannerDateSelected>(_onDateSelected);
    on<PlannerWeekChanged>(_onWeekChanged);
    on<PlannerTaskAdded>(_onTaskAdded);
    on<PlannerTaskUpdated>(_onTaskUpdated);
    on<PlannerTaskToggled>(_onTaskToggled);
    on<PlannerTaskDeleted>(_onTaskDeleted);
  }

  // ── Static helpers (no widget dependencies) ─────────────────────────────────

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Returns the Monday of the week that contains [date].
  static DateTime _mondayOf(DateTime date) =>
      _dateOnly(date).subtract(Duration(days: date.weekday - 1));

  // ── Event handlers ──────────────────────────────────────────────────────────

  /// Called once when the planner screen opens — loads today's tasks.
  Future<void> _onStarted(
    PlannerStarted event,
    Emitter<PlannerState> emit,
  ) async {
    await _loadDay(state.selectedDate, emit, showLoading: true);
  }

  /// Selecting a day loads its tasks (from cache when already fetched).
  Future<void> _onDateSelected(
    PlannerDateSelected event,
    Emitter<PlannerState> emit,
  ) async {
    final date = _dateOnly(event.date);
    emit(state.copyWith(selectedDate: date));

    // Cache hit → nothing to fetch, the UI already has this day's tasks.
    if (state.tasksByDate.containsKey(date)) return;
    await _loadDay(date, emit, showLoading: true);
  }

  /// Swiping to a different week only updates the header label — days load
  /// lazily as the user taps them.
  void _onWeekChanged(PlannerWeekChanged event, Emitter<PlannerState> emit) {
    emit(state.copyWith(visibleWeekStart: _dateOnly(event.weekStart)));
  }

  /// Persists the new task, then reloads the day so the generated id is in play.
  Future<void> _onTaskAdded(
    PlannerTaskAdded event,
    Emitter<PlannerState> emit,
  ) async {
    try {
      await _repository.addTask(
        PlannerTask(
          id: '',
          title: event.title,
          note: event.note,
          date: event.date,
          hour: event.hour,
        ),
      );
    } catch (_) {
      // Non-fatal: the sheet can be re-submitted.
      return;
    }
    await _loadDay(event.date, emit);
  }

  /// Persists an edited task and reloads its day.
  Future<void> _onTaskUpdated(
    PlannerTaskUpdated event,
    Emitter<PlannerState> emit,
  ) async {
    try {
      await _repository.updateTask(event.task);
    } catch (_) {
      return;
    }
    await _loadDay(event.task.date, emit);
  }

  /// Toggles a task's done flag, optimistically, then persists it.
  Future<void> _onTaskToggled(
    PlannerTaskToggled event,
    Emitter<PlannerState> emit,
  ) async {
    final date = state.selectedDate;
    final tasks = state.tasksByDate[date];
    if (tasks == null) return;

    final idx = tasks.indexWhere((t) => t.id == event.taskId);
    if (idx < 0) return;

    final updated = tasks[idx].copyWith(done: !tasks[idx].done);
    final newList = [...tasks]..[idx] = updated;

    // Optimistic UI update — no waiting for the network.
    emit(state.copyWith(tasksByDate: {...state.tasksByDate, date: newList}));

    try {
      await _repository.updateTask(updated);
    } catch (_) {
      // Non-fatal: the optimistic update stays; the user can re-tap to retry.
    }
  }

  /// Deletes a task, optimistically removing it from the selected day.
  Future<void> _onTaskDeleted(
    PlannerTaskDeleted event,
    Emitter<PlannerState> emit,
  ) async {
    final date = state.selectedDate;
    final tasks = state.tasksByDate[date];
    if (tasks == null) return;

    final newList = tasks.where((t) => t.id != event.taskId).toList();
    emit(state.copyWith(tasksByDate: {...state.tasksByDate, date: newList}));

    try {
      await _repository.deleteTask(date: date, id: event.taskId);
    } catch (_) {
      // Non-fatal: reload the day so the tile reappears if the delete failed.
      await _loadDay(date, emit);
    }
  }

  // ── Shared loader ───────────────────────────────────────────────────────────

  /// Fetches [date]'s tasks and merges them into the cache. When [showLoading]
  /// is true the status flips to loading first (used for the initial open and
  /// day switches, where there's nothing yet to show).
  Future<void> _loadDay(
    DateTime date,
    Emitter<PlannerState> emit, {
    bool showLoading = false,
  }) async {
    final day = _dateOnly(date);
    if (showLoading) emit(state.copyWith(status: PlannerStatus.loading));

    try {
      final tasks = await _repository.getTasksForDay(day);
      emit(
        state.copyWith(
          status: PlannerStatus.loaded,
          tasksByDate: {...state.tasksByDate, day: tasks},
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: PlannerStatus.error,
          errorMessage: 'Could not load your plan. Please try again.',
        ),
      );
    }
  }
}
