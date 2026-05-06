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

/// Triggered after an action elsewhere (e.g. toggling a habit on the home
/// page or editing a habit on the manage screen) so the insights cache
/// is re-fetched and stays consistent with home.
final class InsightsRefreshRequested extends InsightsEvent {}
