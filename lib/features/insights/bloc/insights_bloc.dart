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
          weekData: const {},
        ),
      ) {
    on<InsightsStarted>(_onStarted);
    on<InsightsWeekChanged>(_onWeekChanged);
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
      // Fetch the visible week, the habit list, and the completion history in
      // parallel — the collection heatmaps need the last two.
      final results = await Future.wait([
        _repository.getSummaryForWeek(state.visibleWeekStart),
        _repository.getAllHabits(),
        _repository.getCompletionHistory(historyDays),
      ]);

      emit(
        state.copyWith(
          status: InsightsStatus.loaded,
          weekData: results[0] as Map<DateTime, DaySummary>,
          habits: results[1] as List<HabitDefinition>,
          completionHistory: results[2] as Map<DateTime, Set<String>>,
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

    // Skip fetch if all 7 days of this week are already cached.
    if (_isWeekCached(event.weekStart)) return;

    try {
      final newWeekData = await _repository.getSummaryForWeek(event.weekStart);

      // Merge into the existing cache so previously loaded weeks are preserved.
      emit(state.copyWith(weekData: {...state.weekData, ...newWeekData}));
    } catch (_) {
      // Non-fatal: bars just show 0 for the uncached week.
    }
  }

  /// Re-fetches the visible week so changes made elsewhere
  /// (toggle on home, edit/delete on manage) are reflected here.
  Future<void> _onRefreshRequested(
    InsightsRefreshRequested event,
    Emitter<InsightsState> emit,
  ) async {
    try {
      final results = await Future.wait([
        _repository.getSummaryForWeek(state.visibleWeekStart),
        _repository.getAllHabits(),
        _repository.getCompletionHistory(historyDays),
      ]);

      emit(
        state.copyWith(
          status: InsightsStatus.loaded,
          weekData: results[0] as Map<DateTime, DaySummary>,
          habits: results[1] as List<HabitDefinition>,
          completionHistory: results[2] as Map<DateTime, Set<String>>,
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
