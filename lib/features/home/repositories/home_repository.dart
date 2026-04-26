import 'package:purepath/features/home/models/day_summary.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home repository — abstract interface
//
// HomeBloc depends only on this interface, not on any concrete implementation.
// To connect Firestore, create a FirestoreHomeRepository that implements this
// and swap it in di.dart — HomeBloc and the UI don't need to change at all.
// ─────────────────────────────────────────────────────────────────────────────

abstract class HomeRepository {
  /// Fetches habit summaries for a full week.
  ///
  /// [weekStart] is always the Monday of the target week (time stripped to 00:00).
  /// Returns a map of date → [DaySummary] with exactly 7 entries (Mon → Sun).
  Future<Map<DateTime, DaySummary>> getSummaryForWeek(DateTime weekStart);
}
