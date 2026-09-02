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
    on<PlannerMonthChanged>(_onMonthChanged);
    on<PlannerTaskAdded>(_onTaskAdded);
    on<PlannerTaskUpdated>(_onTaskUpdated);
    on<PlannerTaskToggled>(_onTaskToggled);
    on<PlannerTaskDeleted>(_onTaskDeleted);
    on<PlannerTaskMoved>(_onTaskMoved);
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
    // Prefetch the rest of the visible week so the calendar's completion rings
    // are populated for every day, not just the selected one.
    await _preloadWeek(state.visibleWeekStart, emit);
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

  /// Swiping to a different week updates the header label and prefetches that
  /// week's days so their completion rings render immediately.
  Future<void> _onWeekChanged(
    PlannerWeekChanged event,
    Emitter<PlannerState> emit,
  ) async {
    final monday = _dateOnly(event.weekStart);
    emit(state.copyWith(visibleWeekStart: monday));
    await _preloadWeek(monday, emit);
  }

  /// Opening the month sheet (or paging to another month) prefetches that whole
  /// month so every date tile can show its completion ring.
  Future<void> _onMonthChanged(
    PlannerMonthChanged event,
    Emitter<PlannerState> emit,
  ) async {
    await _preloadMonth(event.month, emit);
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

  /// Moves a task to a new day/hour. Within the same day it's a plain hour
  /// change; across days the task is removed from its old day document and
  /// re-added to the new one (day is carried by the parent doc, so a task can't
  /// simply be "updated" onto another date). Afterwards both affected days are
  /// reloaded and the view follows the task to its new home.
  Future<void> _onTaskMoved(
    PlannerTaskMoved event,
    Emitter<PlannerState> emit,
  ) async {
    final oldDate = _dateOnly(event.task.date);
    final newDate = _dateOnly(event.newDate);
    final sameDay = oldDate == newDate;

    if (sameDay && event.task.hour == event.newHour) return; // no-op

    try {
      if (sameDay) {
        await _repository.updateTask(event.task.copyWith(hour: event.newHour));
      } else {
        // Moving a completed task to a day later than today resets it to
        // not-done (you'll do it again then); moving to today or the past keeps
        // its completion.
        final movedDone = event.task.done && !newDate.isAfter(_today);
        await _repository.deleteTask(date: oldDate, id: event.task.id);
        // addTask stamps a fresh id and preserves title/note.
        await _repository.addTask(
          event.task.copyWith(
            date: newDate,
            hour: event.newHour,
            done: movedDone,
          ),
        );
      }
    } catch (_) {
      // Non-fatal: reload the source day so nothing appears lost.
      await _loadDay(oldDate, emit);
      return;
    }

    await _loadDay(oldDate, emit);
    if (!sameDay) await _loadDay(newDate, emit);

    // Follow the task: select the destination day and bring its week into view.
    emit(
      state.copyWith(
        selectedDate: newDate,
        visibleWeekStart: _mondayOf(newDate),
      ),
    );
  }

  /// Fetches any not-yet-cached days of the week starting at [weekStart] and
  /// merges them into the cache in one emit. Best-effort: preload failures are
  /// swallowed so the calendar simply shows empty rings for those days.
  Future<void> _preloadWeek(
    DateTime weekStart,
    Emitter<PlannerState> emit,
  ) async {
    final monday = _dateOnly(weekStart);
    final missing = [
      for (int i = 0; i < 7; i++)
        if (!state.tasksByDate.containsKey(monday.add(Duration(days: i))))
          monday.add(Duration(days: i)),
    ];
    if (missing.isEmpty) return;

    try {
      final results = await Future.wait(
        missing.map(_repository.getTasksForDay),
      );
      final merged = {...state.tasksByDate};
      for (var i = 0; i < missing.length; i++) {
        merged[missing[i]] = results[i];
      }
      emit(state.copyWith(tasksByDate: merged));
    } catch (_) {
      // Non-fatal: rings stay empty for the un-fetched days.
    }
  }

  /// Fetches any not-yet-cached days of [month] (1 … last day) and merges them
  /// into the cache in one emit. Best-effort — same contract as [_preloadWeek].
  Future<void> _preloadMonth(
    DateTime month,
    Emitter<PlannerState> emit,
  ) async {
    final year = month.year;
    final m = month.month;
    // Day 0 of the next month == last day of this month.
    final daysInMonth = DateTime(year, m + 1, 0).day;
    final missing = [
      for (int d = 1; d <= daysInMonth; d++)
        if (!state.tasksByDate.containsKey(DateTime(year, m, d)))
          DateTime(year, m, d),
    ];
    if (missing.isEmpty) return;

    try {
      final results = await Future.wait(
        missing.map(_repository.getTasksForDay),
      );
      final merged = {...state.tasksByDate};
      for (var i = 0; i < missing.length; i++) {
        merged[missing[i]] = results[i];
      }
      emit(state.copyWith(tasksByDate: merged));
    } catch (_) {
      // Non-fatal: rings stay empty for the un-fetched days.
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
