import 'package:bloc/bloc.dart';
import 'package:purepath/features/home/models/day_summary.dart';
import 'package:purepath/features/home/models/habit_model.dart';
import 'package:purepath/features/home/repositories/home_repository.dart';

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
  }

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

  // ── Event handlers ────────────────────────────────────────────────────────

  /// Called once when the insights screen opens.
  /// Loads data for the current week.
  Future<void> _onStarted(
    InsightsStarted event,
    Emitter<InsightsState> emit,
  ) async {
    try {
      final weekData = await _repository.getSummaryForWeek(
        state.visibleWeekStart,
      );
      emit(state.copyWith(status: InsightsStatus.loaded, weekData: weekData));
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

  // ── Cache helpers ─────────────────────────────────────────────────────────

  /// Returns true if all 7 days of the given week are already in [weekData].
  bool _isWeekCached(DateTime weekStart) {
    return List.generate(7, (i) => weekStart.add(Duration(days: i))).every(
      (date) => state.weekData.containsKey(date),
    );
  }
}
