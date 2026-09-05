part of 'home_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home status
// ─────────────────────────────────────────────────────────────────────────────

enum HomeStatus { loading, loaded, error }

// ─────────────────────────────────────────────────────────────────────────────
// Home state
//
// Single immutable state class — UI always reads from one place.
// [weekData] is a cache: once a week is loaded it stays in memory while
// the home screen is alive (IndexedStack keeps it alive).
// ─────────────────────────────────────────────────────────────────────────────

class HomeState {
  /// Whether the bloc is loading, loaded, or errored.
  final HomeStatus status;

  /// The day whose detail is shown below the calendar.
  final DateTime selectedDate;

  /// The Monday of the week currently visible in the calendar.
  final DateTime visibleWeekStart;

  /// Cache of all fetched summaries. Keys are date-only DateTimes (midnight).
  /// Persists across week swipes so already-loaded weeks aren't re-fetched.
  final Map<DateTime, DaySummary> weekData;

  /// Non-null only when [status] == HomeStatus.error.
  final String? errorMessage;

  const HomeState({
    required this.status,
    required this.selectedDate,
    required this.visibleWeekStart,
    required this.weekData,
    this.errorMessage,
  });

  // ── Convenience getter ─────────────────────────────────────────────────────

  /// Shortcut for the summary of the currently selected day.
  /// Null while loading or if the date isn't cached yet.
  DaySummary? get selectedDaySummary => weekData[selectedDate];

  // ── copyWith ───────────────────────────────────────────────────────────────

  HomeState copyWith({
    HomeStatus? status,
    DateTime? selectedDate,
    DateTime? visibleWeekStart,
    Map<DateTime, DaySummary>? weekData,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      visibleWeekStart: visibleWeekStart ?? this.visibleWeekStart,
      weekData: weekData ?? this.weekData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
