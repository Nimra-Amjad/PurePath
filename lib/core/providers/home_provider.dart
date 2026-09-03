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
//      id:              <doc id, also stored as a field for convenience>
//      userId:          <Firebase auth uid of the creator>
//      title:           String
//      type:            String  (HabitType.name — custom | predefined)
//      scheduleType:    String  (HabitSchedule.name — everyDay | weekDays | monthDays)
//      weekDays:        [int]   (0 = Mon … 6 = Sun; used when scheduleType == weekDays)
//      monthDays:       [int]   (1 … 31;            used when scheduleType == monthDays)
//      reminderEnabled: bool    (whether a reminder notification is set)
//      reminderTime:    String  (e.g. "7:30 AM"; empty when no reminder)
//      startDateMillis: int     (local-midnight millis — first active day)
//      endDateMillis:   int?    (local-midnight millis — last active day, or null)
//      createdAt:       Timestamp
//    }
//    (Habits no longer have a `category`; older docs may still carry a legacy
//     `isDaily` bool, which is read as everyDay/weekDays for back-compat.)
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
  ///
  /// Each day is fetched *independently* and resiliently (see [_fetchDayEntry]):
  /// a single flaky read can no longer reject the whole week. This was the root
  /// cause of "all previous days show as not completed" — one transient
  /// cold-start error inside a `Future.wait` used to blank the entire week.
  Future<Map<DateTime, Map<String, dynamic>?>> fetchWeekDocs(
    String uid,
    DateTime weekStart,
  ) async {
    final futures = List.generate(7, (i) {
      final date = _dateOnly(weekStart.add(Duration(days: i)));
      return _fetchDayEntry(uid, date);
    });
    final results = await Future.wait(futures);
    return Map.fromEntries(results);
  }

  /// One day's doc, resilient to transient cold-start failures: retry the
  /// server read, then fall back to the offline cache (which holds already-
  /// synced completions), and only give up to `null` as a last resort.
  Future<MapEntry<DateTime, Map<String, dynamic>?>> _fetchDayEntry(
    String uid,
    DateTime date,
  ) async {
    final ref = _daysRef(uid).doc(_dayDocId(date));
    try {
      final snap = await _withRetry(() => ref.get());
      return MapEntry(date, snap.data());
    } catch (_) {
      try {
        final cached = await ref.get(const GetOptions(source: Source.cache));
        return MapEntry(date, cached.data());
      } catch (_) {
        return MapEntry(date, null);
      }
    }
  }

  /// The most recent [limit] day-docs for [uid], newest first. Uses a single
  /// ordered query (one round-trip) instead of [limit] individual doc reads.
  /// Days the user never recorded simply aren't returned.
  ///
  /// Retries a transient failure and falls back to the offline cache so a
  /// cold-start blip doesn't render the whole collection heatmap as "missed".
  Future<List<Map<String, dynamic>>> fetchRecentDayDocs(
    String uid,
    int limit,
  ) async {
    final query = _daysRef(uid)
        .orderBy('dateMillis', descending: true)
        .limit(limit);
    try {
      final snap = await _withRetry(() => query.get());
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      try {
        final cached = await query.get(const GetOptions(source: Source.cache));
        return cached.docs.map((d) => d.data()).toList();
      } catch (_) {
        return const [];
      }
    }
  }

  /// Runs [op], retrying a few times on transient errors before rethrowing.
  /// Firestore's first reads after a cold start can briefly throw
  /// `unavailable`/deadline while the gRPC channel warms up; without this a
  /// single blip surfaces as "everything not completed".
  static Future<T> _withRetry<T>(Future<T> Function() op) async {
    const delays = [
      Duration(milliseconds: 200),
      Duration(milliseconds: 500),
      Duration(milliseconds: 1000),
    ];
    Object? lastError;
    for (var attempt = 0; attempt <= delays.length; attempt++) {
      try {
        return await op();
      } catch (e) {
        lastError = e;
        if (attempt == delays.length) break;
        await Future.delayed(delays[attempt]);
      }
    }
    throw lastError!;
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
