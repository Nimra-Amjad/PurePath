import 'package:purepath/features/planner/models/planner_task.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Planner repository — abstract interface
//
// PlannerBloc depends only on this interface, not on any concrete
// implementation. To connect Firestore, create a FirestorePlannerRepository
// that implements this and swap it in — the bloc and UI don't change.
// ─────────────────────────────────────────────────────────────────────────────

abstract class PlannerRepository {
  /// Returns every task scheduled on [date], sorted by hour (earliest first).
  /// [date] is normalised to local midnight by the implementation.
  Future<List<PlannerTask>> getTasksForDay(DateTime date);

  /// Creates a new task. Implementations assign a unique id — the [task.id]
  /// passed in is ignored.
  Future<void> addTask(PlannerTask task);

  /// Persists changes to an existing task ([task.id] identifies which one,
  /// [task.date] which day document it lives in).
  Future<void> updateTask(PlannerTask task);

  /// Permanently removes the task with [id] from [date]'s day document.
  Future<void> deleteTask({required DateTime date, required String id});
}
