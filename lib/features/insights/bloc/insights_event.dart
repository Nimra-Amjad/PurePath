part of 'insights_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Insights events
//
// sealed = exhaustive — the compiler tells you if you forget a case.
// ─────────────────────────────────────────────────────────────────────────────

sealed class InsightsEvent {}

/// Triggered once when the insights screen first opens.
/// The bloc loads data for the current week.
final class InsightsStarted extends InsightsEvent {}

/// Triggered when the user taps the prev/next week arrow.
/// [weekStart] is always the Monday of the target week.
final class InsightsWeekChanged extends InsightsEvent {
  final DateTime weekStart;
  InsightsWeekChanged(this.weekStart);
}

/// Triggered when the user taps the prev/next month arrow on the Monthly tab.
/// [monthStart] is always the first day (midnight) of the target month. The
/// bloc extends the loaded completion history if the month falls outside it.
final class InsightsMonthChanged extends InsightsEvent {
  final DateTime monthStart;
  InsightsMonthChanged(this.monthStart);
}

/// Triggered when the Yearly tab is opened or the user pages to another year.
/// [year] is the target calendar year. The bloc extends the loaded completion
/// history so the full-year grids have data.
final class InsightsYearChanged extends InsightsEvent {
  final int year;
  InsightsYearChanged(this.year);
}

/// Triggered after a structural change elsewhere (adding, editing, or deleting
/// a habit) so the insights cache is re-fetched and stays consistent with home.
final class InsightsRefreshRequested extends InsightsEvent {}

/// Triggered the instant the user toggles a habit's completion on the home
/// screen. Updates the cached state in memory — no network round-trip — so the
/// dot fills immediately. Re-reading Firestore here instead would race the
/// write home is still persisting, which is what makes the dot lag one toggle
/// behind (a completion only appearing after the *next* toggle).
final class InsightsCompletionToggled extends InsightsEvent {
  final String habitId;
  final DateTime date;
  final bool completed;

  InsightsCompletionToggled({
    required this.habitId,
    required this.date,
    required this.completed,
  });
}
