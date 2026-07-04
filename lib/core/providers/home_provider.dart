import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeProvider
//
// The only place that touches Firestore for habit + insights data. Owns the
// schema:
//
// 1) `users/{uid}/habits`  — habit definitions (one doc per habit).
//    {
//      id:           <doc id, also stored as a field for convenience>
//      userId:       <Firebase auth uid of the creator>
//      title:        String
//      category:     String   (HabitCategory.name)
//      type:         String   (HabitType.name)
//      isDaily:      bool
//      weekDays:     [int]    (0 = Mon … 6 = Sun, empty when isDaily)
//      reminderTime: String
//      createdAt:    Timestamp
//    }
//
// 2) `insights` — one doc per (user, date) recording which habits the user
//    completed that day. Doc id is deterministic: `<uid>_<yyyymmdd>` so we
//    can read 7 days at a time by direct doc id (no composite index needed).
//    {
//      userId:     <uid>
//      date:       "yyyy-MM-dd"
//      dateMillis: int    (millis since epoch at local midnight)
//      habits:     [ { id, hasDone } ]
//    }
//
// Works with raw snapshots / maps only — model mapping and business rules
// (summaries, streaks) live in FirestoreHomeRepository.
// ─────────────────────────────────────────────────────────────────────────────

class HomeProvider {
  static const _kUsers = 'users';
  static const _kHabits = 'habits';
  static const _kInsights = 'insights';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HomeProvider({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// The signed-in user's uid, or null when no user is authenticated.
  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _habitsRef(String uid) =>
      _firestore.collection(_kUsers).doc(uid).collection(_kHabits);

  CollectionReference<Map<String, dynamic>> get _insightsRef =>
      _firestore.collection(_kInsights);

  // ── Habits ─────────────────────────────────────────────────────────────────

  /// Raw habit docs for [uid] (unsorted — ordering is a repository concern).
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchHabitDocs(
    String uid,
  ) async {
    final query = await _habitsRef(uid).get();
    return query.docs;
  }

  /// Creates a habit doc with a generated id, stamping id / userId /
  /// createdAt on top of [data].
  Future<void> createHabit(String uid, Map<String, dynamic> data) async {
    final docRef = _habitsRef(uid).doc();
    await docRef.set({
      ...data,
      'id': docRef.id,
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateHabit(
    String uid,
    String habitId,
    Map<String, dynamic> data,
  ) async {
    await _habitsRef(uid).doc(habitId).update(data);
  }

  Future<void> deleteHabit(String uid, String habitId) async {
    await _habitsRef(uid).doc(habitId).delete();
  }

  // ── Insights (per-day completion docs) ─────────────────────────────────────

  /// Raw insights doc for (uid, date), or null when the day has no record.
  Future<Map<String, dynamic>?> fetchDayDoc(String uid, DateTime date) async {
    final snap = await _insightsRef.doc(_insightsDocId(uid, date)).get();
    return snap.data();
  }

  /// Raw insights docs for the 7 days starting at [weekStart], fetched in
  /// parallel by deterministic doc id. Missing days map to null.
  Future<Map<DateTime, Map<String, dynamic>?>> fetchWeekDocs(
    String uid,
    DateTime weekStart,
  ) async {
    final futures = List.generate(7, (i) {
      final date = _dateOnly(weekStart.add(Duration(days: i)));
      return _insightsRef.doc(_insightsDocId(uid, date)).get().then(
            (snap) => MapEntry(date, snap.data()),
          );
    });
    final results = await Future.wait(futures);
    return Map.fromEntries(results);
  }

  /// Upserts the (uid, date) insights doc with the given habits array.
  Future<void> writeDayHabits(
    String uid,
    DateTime date,
    List<Map<String, dynamic>> habits,
  ) async {
    final dateOnly = _dateOnly(date);
    await _insightsRef.doc(_insightsDocId(uid, dateOnly)).set({
      'userId': uid,
      'date': _dateString(dateOnly),
      'dateMillis': dateOnly.millisecondsSinceEpoch,
      'habits': habits,
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Deterministic doc id so repeated toggles upsert a single record per day.
  static String _insightsDocId(String uid, DateTime date) =>
      '${uid}_${_dateString(date).replaceAll('-', '')}';

  static String _dateString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
