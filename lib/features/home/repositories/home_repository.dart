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

  /// Creates a new habit for the current user.
  /// Implementations are responsible for assigning a unique id —
  /// the [definition.id] passed in is ignored.
  Future<void> addHabit(HabitDefinition definition);

  /// Permanently removes the habit with [id].
  /// The habit will no longer appear in future [getSummaryForWeek] results.
  Future<void> deleteHabit(String id);

  /// Persists changes made to an existing habit.
  /// The updated [definition] replaces the previous version with the same id.
  Future<void> updateHabit(HabitDefinition definition);

  // ── Habit completions ──────────────────────────────────────────────────────

  /// Persists the user's progress on [habitId] for a specific [date].
  ///
  /// [progress] is 0.0 (not done) → 1.0 (fully completed).
  /// Implementations should upsert so repeated calls overwrite the previous value.
  Future<void> setHabitProgress({
    required String habitId,
    required DateTime date,
    required double progress,
  });

  /// Computes the user's current consecutive-day streak by walking backward
  /// through the day docs and counting unbroken "completed" days.
  ///
  /// A day is "completed" if it has at least one habit with hasDone=true.
  /// The walk starts at today (or yesterday, if today has no completions yet
  /// — today is a grace window) and stops at the first non-completed day.
  /// Backfilling a previously missed day naturally repairs the streak, since
  /// the result depends only on the persisted data, not on the order of
  /// toggles.
  Future<int> calculateCurrentStreak();
}
