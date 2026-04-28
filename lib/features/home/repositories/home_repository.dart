import 'package:purepath/features/home/models/day_summary.dart';
import 'package:purepath/features/home/models/habit_definition.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home repository — abstract interface
//
// HomeBloc depends only on this interface, not on any concrete implementation.
// To connect Firestore, create a FirestoreHomeRepository that implements this
// and swap it in — HomeBloc and the UI don't need to change at all.
// ─────────────────────────────────────────────────────────────────────────────

abstract class HomeRepository {
  // ── Daily / weekly data ────────────────────────────────────────────────────

  /// Fetches habit summaries for a full week.
  ///
  /// [weekStart] is always the Monday of the target week (time stripped 00:00).
  /// Returns a map of date → [DaySummary] with exactly 7 entries (Mon → Sun).
  Future<Map<DateTime, DaySummary>> getSummaryForWeek(DateTime weekStart);

  // ── Habit management ───────────────────────────────────────────────────────

  /// Returns the complete list of habits the user has created, in creation order.
  Future<List<HabitDefinition>> getAllHabits();

  /// Permanently removes the habit with [id].
  /// The habit will no longer appear in future [getSummaryForWeek] results.
  Future<void> deleteHabit(String id);

  /// Persists changes made to an existing habit.
  /// The updated [definition] replaces the previous version with the same id.
  Future<void> updateHabit(HabitDefinition definition);
}
