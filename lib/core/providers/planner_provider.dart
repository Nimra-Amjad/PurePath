import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PlannerProvider
//
// The only place that touches Firestore for planner data. Owns the schema:
//
//   `planner/{uid}/days/{dd-MM-yyyy}` — one doc per day, holding that day's
//   whole task list as an array.
//   {
//     date:  "30-08-2026"   (dd-MM-yyyy — also the document id)
//     tasks: [
//       { id, title, note, hour (0=12 AM … 23=11 PM), done },
//       ...
//     ]
//   }
//
// A day is read/written as a single document by its deterministic id, so no
// query or composite index is needed, and security rules gate on the {uid}
// path segment. Callers read-modify-write the whole `tasks` array (mutating one
// task rewrites the array) — mirrors how the insights day docs are handled.
//
// Works with raw snapshots / maps only — model mapping lives in
// FirestorePlannerRepository.
// ─────────────────────────────────────────────────────────────────────────────

class PlannerProvider {
  static const _kPlanner = 'planner';
  static const _kDays = 'days';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PlannerProvider({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// The signed-in user's uid, or null when no user is authenticated.
  String? get currentUid => _auth.currentUser?.uid;

  /// Per-user subcollection of day docs: `planner/{uid}/days`.
  CollectionReference<Map<String, dynamic>> _daysRef(String uid) =>
      _firestore.collection(_kPlanner).doc(uid).collection(_kDays);

  // ── Reads ──────────────────────────────────────────────────────────────────

  /// Raw day doc for (uid, date), or null when the day has no tasks yet.
  Future<Map<String, dynamic>?> fetchDay(String uid, DateTime date) async {
    final snap = await _daysRef(uid).doc(_dayDocId(date)).get();
    return snap.data();
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Upserts the (uid, date) day doc with the given [tasks] array, merging so
  /// the `date` field and any future sibling fields survive. The array itself
  /// is replaced wholesale — callers read-modify-write the full list.
  Future<void> writeDayTasks(
    String uid,
    DateTime date,
    List<Map<String, dynamic>> tasks,
  ) async {
    final day = _dateOnly(date);
    await _daysRef(uid).doc(_dayDocId(day)).set({
      'date': _dayDocId(day),
      'tasks': tasks,
    }, SetOptions(merge: true));
  }

  /// A fresh, collision-free id for a new task (a client-side Firestore auto id;
  /// no write happens). Tasks live in an array, so they have no doc of their own
  /// to borrow an id from.
  String newTaskId(String uid) => _daysRef(uid).doc().id;

  // ── Helpers ────────────────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Deterministic day doc id in `dd-MM-yyyy` form (e.g. "30-08-2026").
  static String _dayDocId(DateTime date) {
    final d = _dateOnly(date);
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString().padLeft(4, '0');
    return '$dd-$mm-$yyyy';
  }
}
