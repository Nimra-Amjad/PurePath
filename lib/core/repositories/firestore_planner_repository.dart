import 'package:purepath/core/providers/planner_provider.dart';
import 'package:purepath/core/repositories/planner_repository.dart';
import 'package:purepath/features/planner/models/planner_task.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Firestore planner repository
//
// Business-logic layer between PlannerBloc and PlannerProvider:
//
//   PlannerBloc → FirestorePlannerRepository → PlannerProvider
//
// The provider owns raw Firestore access + the day-document schema. This class
// owns everything on top: model mapping, hour ordering, and the read-modify-
// write of the day's `tasks` array (adding / editing / deleting one task
// rewrites the array, exactly like the insights day docs).
// ─────────────────────────────────────────────────────────────────────────────

class FirestorePlannerRepository implements PlannerRepository {
  final PlannerProvider _provider;

  FirestorePlannerRepository({required PlannerProvider provider})
    : _provider = provider;

  String? get _uid => _provider.currentUid;

  @override
  Future<List<PlannerTask>> getTasksForDay(DateTime date) async {
    final uid = _uid;
    if (uid == null) return const [];

    final data = await _provider.fetchDay(uid, date);
    final tasks = _tasksFromDoc(data, date);

    // Sort by hour client-side so the timeline reads top-to-bottom. A single
    // day never holds enough tasks for the sort cost to matter.
    tasks.sort((a, b) => a.hour.compareTo(b.hour));
    return tasks;
  }

  @override
  Future<void> addTask(PlannerTask task) async {
    final uid = _uid;
    if (uid == null) return;

    final data = await _provider.fetchDay(uid, task.date);
    final tasks = _tasksFromDoc(data, task.date);

    // Stamp a fresh id — array elements have no doc of their own.
    final withId = task.copyWith(id: _provider.newTaskId(uid));
    tasks.add(withId);

    await _writeBack(uid, task.date, tasks);
  }

  @override
  Future<void> updateTask(PlannerTask task) async {
    final uid = _uid;
    if (uid == null) return;

    final data = await _provider.fetchDay(uid, task.date);
    final tasks = _tasksFromDoc(data, task.date);

    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      tasks[idx] = task;
    } else {
      // Not found (e.g. edited from a stale view) — treat as an upsert.
      tasks.add(task);
    }

    await _writeBack(uid, task.date, tasks);
  }

  @override
  Future<void> deleteTask({required DateTime date, required String id}) async {
    final uid = _uid;
    if (uid == null) return;

    final data = await _provider.fetchDay(uid, date);
    final tasks = _tasksFromDoc(data, date)..removeWhere((t) => t.id == id);

    await _writeBack(uid, date, tasks);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Parses the `tasks` array off a day doc into models stamped with [date].
  List<PlannerTask> _tasksFromDoc(Map<String, dynamic>? data, DateTime date) {
    final raw = data?['tasks'] as List? ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => PlannerTask.fromEntry(
              Map<String, dynamic>.from(e),
              date: date,
            ))
        .toList();
  }

  Future<void> _writeBack(String uid, DateTime date, List<PlannerTask> tasks) {
    return _provider.writeDayTasks(
      uid,
      date,
      tasks.map((t) => t.toEntry()).toList(),
    );
  }
}
