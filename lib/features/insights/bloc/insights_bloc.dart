import 'package:bloc/bloc.dart';
import 'package:purepath/features/home/models/day_summary.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/home/models/habit_model.dart';
import 'package:purepath/core/repositories/home_repository.dart';

part 'insights_event.dart';
part 'insights_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Insights BLoC
//
// Responsibilities:
//   • Load habit data for a week from [HomeRepository]
//   • Track which week is currently visible
//   • Cache already-loaded weeks (no redundant fetches on swipe back)
//
// Shares the same [HomeRepository] interface as [HomeBloc] so swapping in
// Firestore later only requires changing one line in [InsightsPage].
// ─────────────────────────────────────────────────────────────────────────────

class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  final HomeRepository _repository;

  InsightsBloc({required HomeRepository repository})
    : _repository = repository,
      super(
        InsightsState(
          status: InsightsStatus.loading,
          visibleWeekStart: _mondayOf(_today),
          visibleMonthStart: _firstOfMonth(_today),
          visibleYear: _today.year,
          weekData: const {},
        ),
      ) {
    on<InsightsStarted>(_onStarted);
    on<InsightsWeekChanged>(_onWeekChanged);
    on<InsightsMonthChanged>(_onMonthChanged);
    on<InsightsYearChanged>(_onYearChanged);
    on<InsightsRefreshRequested>(_onRefreshRequested);
    on<InsightsCompletionToggled>(_onCompletionToggled);
  }

  /// How many days of completion history to pull for the collection heatmaps.
  /// ~15 weeks fills the dot grid comfortably while keeping the read cheap
  /// (a single ordered Firestore query, not one read per day).
  static const historyDays = 105;

  // ── Static helpers ────────────────────────────────────────────────────────

  /// Today's date with time stripped (always midnight).
  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Returns the Monday of the week that contains [date].
  static DateTime _mondayOf(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Returns the first day (midnight) of the month that contains [date].
  static DateTime _firstOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  /// [date] with the time stripped (local midnight) so it matches the keys used
  /// in [InsightsState.completionHistory] and [InsightsState.weekData].
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // ── Event handlers ────────────────────────────────────────────────────────

  /// Called once when the insights screen opens.
  /// Loads data for the current week.
  Future<void> _onStarted(
    InsightsStarted event,
    Emitter<InsightsState> emit,
  ) async {
    try {
      // Fetch the visible week + the week before it (for the "vs last week"
      // delta), the habit list, and the completion history in parallel — the
      // habit matrix needs the completion history.
      final prevWeekStart = state.visibleWeekStart.subtract(
        const Duration(days: 7),
      );
      final results = await Future.wait([
        _repository.getSummaryForWeek(state.visibleWeekStart),
        _repository.getAllHabits(),
        _repository.getCompletionHistory(historyDays),
        _repository.getSummaryForWeek(prevWeekStart),
      ]);

      emit(
        state.copyWith(
          status: InsightsStatus.loaded,
          weekData: {
            ...results[3] as Map<DateTime, DaySummary>,
            ...results[0] as Map<DateTime, DaySummary>,
          },
          habits: results[1] as List<HabitDefinition>,
          completionHistory: results[2] as Map<DateTime, Set<String>>,
          historyDaysLoaded: historyDays,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InsightsStatus.error,
          errorMessage: 'Could not load data. Please try again.',
        ),
      );
    }
  }

  /// Called when the user taps prev/next week arrow.
  /// Updates [visibleWeekStart] immediately (header label updates instantly),
  /// then fetches the week's data if not already cached.
  Future<void> _onWeekChanged(
    InsightsWeekChanged event,
    Emitter<InsightsState> emit,
  ) async {
    // Update the header right away — no waiting for the network.
    emit(state.copyWith(visibleWeekStart: event.weekStart));

    // Load the visible week and the one before it (for the delta), skipping any
    // week already fully cached.
    final prevWeekStart = event.weekStart.subtract(const Duration(days: 7));
    final toFetch = [
      event.weekStart,
      prevWeekStart,
    ].where((w) => !_isWeekCached(w)).toList();
    if (toFetch.isEmpty) return;

    try {
      final maps = await Future.wait(
        toFetch.map(_repository.getSummaryForWeek),
      );

      // Merge into the existing cache so previously loaded weeks are preserved.
      final merged = {...state.weekData};
      for (final m in maps) {
        merged.addAll(m);
      }
      emit(state.copyWith(weekData: merged));
    } catch (_) {
      // Non-fatal: bars just show 0 for the uncached week.
    }
  }

  /// Called when the user pages to a different month on the Monthly tab.
  /// Updates the header immediately, then — if the target month is older than
  /// the currently loaded completion history — pulls a wider history window so
  /// the heatmap and per-habit calendars have data.
  Future<void> _onMonthChanged(
    InsightsMonthChanged event,
    Emitter<InsightsState> emit,
  ) async {
    emit(state.copyWith(visibleMonthStart: event.monthStart));

    // Days of history needed to reach the first day of the target month
    // (plus the whole month), counted back from today.
    final neededDays = _today.difference(event.monthStart).inDays + 31;
    if (neededDays <= state.historyDaysLoaded) return;

    try {
      final history = await _repository.getCompletionHistory(neededDays);
      emit(
        state.copyWith(
          completionHistory: history,
          historyDaysLoaded: neededDays,
        ),
      );
    } catch (_) {
      // Non-fatal: the month just shows empty cells for the uncovered days.
    }
  }

  /// Called when the Yearly tab opens or the user pages to another year.
  /// Updates the header, then loads enough completion history to cover the whole
  /// target year (Jan 1 → today) when it falls outside the loaded window.
  Future<void> _onYearChanged(
    InsightsYearChanged event,
    Emitter<InsightsState> emit,
  ) async {
    if (event.year != state.visibleYear) {
      emit(state.copyWith(visibleYear: event.year));
    }

    // Days of history needed to reach Jan 1 of the target year, counted back
    // from today (plus a full year of margin).
    final neededDays =
        _today.difference(DateTime(event.year, 1, 1)).inDays + 366;
    if (neededDays <= state.historyDaysLoaded) return;

    try {
      final history = await _repository.getCompletionHistory(neededDays);
      emit(
        state.copyWith(
          completionHistory: history,
          historyDaysLoaded: neededDays,
        ),
      );
    } catch (_) {
      // Non-fatal: the year just shows empty cells for the uncovered days.
    }
  }

  /// Re-fetches the visible week so changes made elsewhere
  /// (toggle on home, edit/delete on manage) are reflected here.
  Future<void> _onRefreshRequested(
    InsightsRefreshRequested event,
    Emitter<InsightsState> emit,
  ) async {
    try {
      final prevWeekStart = state.visibleWeekStart.subtract(
        const Duration(days: 7),
      );
      final results = await Future.wait([
        _repository.getSummaryForWeek(state.visibleWeekStart),
        _repository.getAllHabits(),
        _repository.getCompletionHistory(historyDays),
        _repository.getSummaryForWeek(prevWeekStart),
      ]);

      emit(
        state.copyWith(
          status: InsightsStatus.loaded,
          // Merge over the existing cache so other loaded weeks survive.
          weekData: {
            ...state.weekData,
            ...results[3] as Map<DateTime, DaySummary>,
            ...results[0] as Map<DateTime, DaySummary>,
          },
          habits: results[1] as List<HabitDefinition>,
          completionHistory: results[2] as Map<DateTime, Set<String>>,
          historyDaysLoaded: historyDays,
        ),
      );
    } catch (_) {
      // Non-fatal: keep showing the previous (slightly stale) data.
    }
  }

  /// Optimistically reflects a home-screen toggle in the cached state so the
  /// collection dot (and the weekly bar/stats, if that day is loaded) update
  /// instantly — without re-reading Firestore, which would race the write home
  /// is still persisting.
  void _onCompletionToggled(
    InsightsCompletionToggled event,
    Emitter<InsightsState> emit,
  ) {
    final date = _dateOnly(event.date);

    // 1) Completion history → drives the collection heatmap dots.
    final history = {...state.completionHistory};
    final completedIds = {...(history[date] ?? const <String>{})};
    if (event.completed) {
      completedIds.add(event.habitId);
    } else {
      completedIds.remove(event.habitId);
    }
    history[date] = completedIds;

    // 2) Week data → keeps the bar chart + weekly stats in sync when that day
    //    is already cached. (Untouched otherwise.)
    final weekData = {...state.weekData};
    final summary = weekData[date];
    if (summary != null) {
      final updatedHabits = summary.habits.map((h) {
        if (h.id != event.habitId) return h;
        return HabitModel(
          id: h.id,
          title: h.title,
          subtitle: h.subtitle,
          frequencyLabel: h.frequencyLabel,
          progress: event.completed ? 1.0 : 0.0,
          colorValue: h.colorValue,
        );
      }).toList();
      weekData[date] = DaySummary(date: summary.date, habits: updatedHabits);
    }

    emit(state.copyWith(completionHistory: history, weekData: weekData));
  }

  // ── Cache helpers ─────────────────────────────────────────────────────────

  /// Returns true if all 7 days of the given week are already in [weekData].
  bool _isWeekCached(DateTime weekStart) {
    return List.generate(7, (i) => weekStart.add(Duration(days: i))).every(
      (date) => state.weekData.containsKey(date),
    );
  }
}
