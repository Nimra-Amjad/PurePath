import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeProvider
//
// The only place that touches Firestore for habit + insights data. Owns the
// schema:
//
// 1) `habits/{uid}/habits`  — habit definitions (one doc per habit).
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
// 2) `insights/{uid}/days/{yyyymmdd}` — one doc per (user, date) recording
//    which habits the user completed that day. Days live in a per-user
//    subcollection and the day is the doc id, so we can read 7 days at a time
//    by direct doc id (no composite index needed) and security rules gate on
//    the {uid} path segment. The uid is implicit in the path, so it's no
//    longer stored as a field.
//    {
//      date:       "yyyy-MM-dd"
//      dateMillis: int    (millis since epoch at local midnight)
//      habits:     [ { id, hasDone, doneAt } ]
//                  doneAt = local-midnight millis of the day the habit was
//                  marked done. The streak counts a completion only when
//                  doneAt matches the habit's own day (on-time); a late
//                  backfill is recorded but doesn't repair a broken streak.
//      frozen:     bool   (optional — true = streak-restored day, counts as
//                          completed even with no habit done)
//      mood:       String (optional — Mood.name, the day's logged mood)
//      note:       String (optional — the day's free-text journal note)
//    }
//
// Works with raw snapshots / maps only — model mapping and business rules
// (summaries, streaks) live in FirestoreHomeRepository.
// ─────────────────────────────────────────────────────────────────────────────

class HomeProvider {
  static const _kHabits = 'habits';
  static const _kInsights = 'insights';
  static const _kDays = 'days';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HomeProvider({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// The signed-in user's uid, or null when no user is authenticated.
  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _habitsRef(String uid) =>
      _firestore.collection(_kHabits).doc(uid).collection(_kHabits);

  /// Per-user subcollection of daily completion docs:
  /// `insights/{uid}/days/{yyyymmdd}`.
  CollectionReference<Map<String, dynamic>> _daysRef(String uid) =>
      _firestore.collection(_kInsights).doc(uid).collection(_kDays);

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
    final snap = await _daysRef(uid).doc(_dayDocId(date)).get();
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
      return _daysRef(uid)
          .doc(_dayDocId(date))
          .get()
          .then((snap) => MapEntry(date, snap.data()));
    });
    final results = await Future.wait(futures);
    return Map.fromEntries(results);
  }

  /// The most recent [limit] day-docs for [uid], newest first. Uses a single
  /// ordered query (one round-trip) instead of [limit] individual doc reads.
  /// Days the user never recorded simply aren't returned.
  Future<List<Map<String, dynamic>>> fetchRecentDayDocs(
    String uid,
    int limit,
  ) async {
    final query = await _daysRef(uid)
        .orderBy('dateMillis', descending: true)
        .limit(limit)
        .get();
    return query.docs.map((d) => d.data()).toList();
  }

  /// Upserts the (uid, date) insights doc with the given habits array.
  ///
  /// Merges so the write only touches `habits` (plus the date keys) and leaves
  /// any sibling fields on the day — `frozen`, `mood`, `note` — untouched. The
  /// habits array itself is still replaced wholesale, which is correct: callers
  /// read-modify-write the full array before calling this.
  Future<void> writeDayHabits(
    String uid,
    DateTime date,
    List<Map<String, dynamic>> habits,
  ) async {
    final dateOnly = _dateOnly(date);
    await _daysRef(uid).doc(_dayDocId(dateOnly)).set({
      'date': _dateString(dateOnly),
      'dateMillis': dateOnly.millisecondsSinceEpoch,
      'habits': habits,
    }, SetOptions(merge: true));
  }

  /// Upserts the (uid, date) reflection onto the day doc, merging so it sits
  /// alongside that day's habits without disturbing them. A null [mood] clears
  /// any previously logged mood for the day.
  Future<void> writeDayReflection(
    String uid,
    DateTime date, {
    required String? mood,
    required String note,
  }) async {
    final dateOnly = _dateOnly(date);
    await _daysRef(uid).doc(_dayDocId(dateOnly)).set({
      'date': _dateString(dateOnly),
      'dateMillis': dateOnly.millisecondsSinceEpoch,
      'mood': mood,
      'note': note,
    }, SetOptions(merge: true));
  }

  /// Marks (uid, date) as a frozen / streak-restored day. Merges so an
  /// existing habits array on that day is preserved, and creates the doc when
  /// the day was never recorded (a truly missed day).
  Future<void> freezeDay(String uid, DateTime date) async {
    final dateOnly = _dateOnly(date);
    await _daysRef(uid).doc(_dayDocId(dateOnly)).set({
      'date': _dateString(dateOnly),
      'dateMillis': dateOnly.millisecondsSinceEpoch,
      'frozen': true,
    }, SetOptions(merge: true));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Deterministic day doc id (`yyyymmdd`) so repeated toggles upsert a single
  /// record per day. The uid lives in the path, not the id.
  static String _dayDocId(DateTime date) =>
      _dateString(date).replaceAll('-', '');

  static String _dateString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
