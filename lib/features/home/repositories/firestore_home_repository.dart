import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purepath/features/home/models/day_summary.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/home/models/habit_model.dart';
import 'package:purepath/features/home/repositories/home_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Firestore home repository
//
// Habit definitions live in a per-user sub-collection; completions live in a
// top-level collection keyed by (user, date):
//
// 1) `users/{uid}/habits`  — habit definitions (one doc per habit the user has).
//    {
//      id:           <doc id, also stored as a field for convenience>
//      userId:       <Firebase auth uid of the creator>
//      title:        String
//      category:     String   (HabitCategory.name)
//      type:         String   (HabitType.name — "custom" when the user built it,
//                              "predefined" when added from the habit library)
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
//      habits:     [
//        { id, hasDone }
//      ]
//    }
//    Title/category/etc. are NOT duplicated here — they're looked up from
//    the `habits` collection at read time. Habits not present in the array
//    — or with hasDone=false — render as unchecked on home and unfilled in
//    the insights bar chart.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreHomeRepository implements HomeRepository {
  static const _kUsers = 'users';
  static const _kHabits = 'habits';
  static const _kInsights = 'insights';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreHomeRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// The signed-in user's `users/{uid}/habits` sub-collection, or null when no
  /// user is authenticated.
  CollectionReference<Map<String, dynamic>>? get _habitsRef {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection(_kUsers).doc(uid).collection(_kHabits);
  }

  CollectionReference<Map<String, dynamic>> get _insightsRef =>
      _firestore.collection(_kInsights);

  // ── HomeRepository implementation ──────────────────────────────────────────

  @override
  Future<List<HabitDefinition>> getAllHabits() async {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return const [];

    final query = await habitsRef.get();

    // Build the habits list and a side-map of createdAt millis in one pass.
    // Doing the lookup inline (instead of calling firstWhere/orElse later)
    // sidesteps a Firestore typing quirk: the static type is
    // `QueryDocumentSnapshot<Map<String, dynamic>>` but the runtime type is
    // the package-private `_JsonQueryDocumentSnapshot`, which makes
    // `orElse: () => docs.first` fail its subtype check at runtime.
    final createdAtById = <String, int>{};
    final habits = query.docs.map((doc) {
      final raw = doc.data();
      final ts = raw['createdAt'];
      createdAtById[doc.id] =
          ts is Timestamp ? ts.millisecondsSinceEpoch : 0;
      return HabitDefinition.fromMap({...raw, 'id': doc.id});
    }).toList();

    // Sort by createdAt client-side so older habits appear first.
    habits.sort((a, b) {
      final ta = createdAtById[a.id] ?? 0;
      final tb = createdAtById[b.id] ?? 0;
      return ta.compareTo(tb);
    });

    return habits;
  }

  @override
  Future<void> addHabit(HabitDefinition definition) async {
    final uid = _uid;
    final habitsRef = _habitsRef;
    if (uid == null || habitsRef == null) return;

    final docRef = habitsRef.doc(); // Firestore-generated unique id.
    await docRef.set({
      ...definition.toMap(),
      'id': docRef.id,
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteHabit(String id) async {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return;

    // Just remove the habit definition. Stale entries in `insights` docs are
    // harmless: getSummaryForWeek joins on the live habits list, so any
    // orphaned ids in the array are simply ignored.
    await habitsRef.doc(id).delete();
  }

  @override
  Future<void> updateHabit(HabitDefinition definition) async {
    final habitsRef = _habitsRef;
    if (habitsRef == null) return;

    await habitsRef.doc(definition.id).update(definition.toMap());
  }

  @override
  Future<void> setHabitProgress({
    required String habitId,
    required DateTime date,
    required double progress,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final dateOnly = _dateOnly(date);
    final docRef = _insightsRef.doc(_insightsDocId(uid, dateOnly));
    final hasDone = progress >= 1.0;

    // Read-modify-write the day's habits array so flipping one habit doesn't
    // overwrite the others' completion state.
    final snap = await docRef.get();
    final List<Map<String, dynamic>> habits = snap.exists
        ? (snap.data()?['habits'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    final entry = <String, dynamic>{'id': habitId, 'hasDone': hasDone};

    final idx = habits.indexWhere((e) => e['id'] == habitId);
    if (idx >= 0) {
      habits[idx] = entry;
    } else {
      habits.add(entry);
    }

    await docRef.set({
      'userId': uid,
      'date': _dateString(dateOnly),
      'dateMillis': dateOnly.millisecondsSinceEpoch,
      'habits': habits,
    });
  }

  @override
  Future<Map<DateTime, DaySummary>> getSummaryForWeek(
    DateTime weekStart,
  ) async {
    final habits = await getAllHabits();

    // Completion data is best-effort: if Firestore rules don't allow reads
    // on `insights`, or the network blips, we still want to render the
    // habits list (just with everything unchecked) instead of erroring out
    // the entire home page.
    Map<String, bool> hasDoneByKey;
    try {
      hasDoneByKey = await _fetchWeekHasDone(weekStart);
    } catch (_) {
      hasDoneByKey = const {};
    }

    final result = <DateTime, DaySummary>{};

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final date = _dateOnly(weekStart.add(Duration(days: dayIndex)));
      final weekDayIndex = date.weekday - 1; // 0 = Mon … 6 = Sun

      final habitsForDay = habits
          .where((h) => h.isActiveOn(date))
          .where(
            (h) => h.isDaily || h.weekDays.contains(weekDayIndex),
          )
          .map((definition) {
            final hasDone = hasDoneByKey[
                  '${definition.id}_${date.millisecondsSinceEpoch}'
                ] ??
                false;
            return HabitModel(
              id: definition.id,
              title: definition.title,
              subtitle: definition.subtitle,
              category: definition.category,
              isDaily: definition.isDaily,
              progress: hasDone ? 1.0 : 0.0,
            );
          })
          .toList();

      result[date] = DaySummary(date: date, habits: habitsForDay);
    }

    return result;
  }

  @override
  Future<int> calculateCurrentStreak() async {
    final uid = _uid;
    if (uid == null) return 0;

    final today = _dateOnly(DateTime.now());

    // Anchor: today if it has any completion, else yesterday (grace window).
    DateTime cursor = today;
    bool cursorDone = await _isDayCompleted(uid, cursor);
    if (!cursorDone) {
      cursor = today.subtract(const Duration(days: 1));
      cursorDone = await _isDayCompleted(uid, cursor);
      if (!cursorDone) return 0;
    }

    // Walk backward day by day, counting consecutive completed days.
    // The 5000 cap matches the top badge threshold; it's just a safety
    // bound, not a reachable limit in practice.
    int streak = 0;
    while (cursorDone && streak < 5000) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
      cursorDone = await _isDayCompleted(uid, cursor);
    }
    return streak;
  }

  Future<bool> _isDayCompleted(String uid, DateTime date) async {
    final snap =
        await _insightsRef.doc(_insightsDocId(uid, date)).get();
    final data = snap.data();
    if (data == null) return false;
    final habits = data['habits'] as List? ?? const [];
    for (final raw in habits) {
      if (raw is Map && raw['hasDone'] == true) return true;
    }
    return false;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Reads the 7 day-docs for the visible week in parallel and returns a
  /// `<habitId>_<dateMillis>` → hasDone map. Direct doc lookups don't need a
  /// composite index, so this works on a fresh project with no index setup.
  Future<Map<String, bool>> _fetchWeekHasDone(DateTime weekStart) async {
    final uid = _uid;
    if (uid == null) return const {};

    final futures = List.generate(7, (i) {
      final date = _dateOnly(weekStart.add(Duration(days: i)));
      return _insightsRef.doc(_insightsDocId(uid, date)).get().then(
            (snap) => MapEntry(date, snap.data()),
          );
    });

    final results = await Future.wait(futures);

    final out = <String, bool>{};
    for (final entry in results) {
      final date = entry.key;
      final data = entry.value;
      if (data == null) continue;
      final list = data['habits'] as List? ?? const [];
      for (final raw in list) {
        if (raw is! Map) continue;
        final habit = Map<String, dynamic>.from(raw);
        final habitId = habit['id'] as String? ?? '';
        final hasDone = habit['hasDone'] as bool? ?? false;
        if (habitId.isEmpty) continue;
        out['${habitId}_${date.millisecondsSinceEpoch}'] = hasDone;
      }
    }
    return out;
  }

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
