import 'package:purepath/features/home/models/day_summary.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/home/models/habit_model.dart';
import 'package:purepath/features/home/repositories/home_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dummy home repository
//
// Returns realistic in-memory habit data so the UI looks meaningful before
// Firestore is connected.
//
// The data is stored in static fields so all instances (HomePage, InsightsPage,
// ManageHabitsPage) share the same list — deleting or editing a habit is
// reflected everywhere instantly.
//
// SWAP GUIDE: Replace DummyHomeRepository() with FirestoreHomeRepository()
// wherever a HomeRepository is created — nothing else needs to change.
// ─────────────────────────────────────────────────────────────────────────────

class DummyHomeRepository implements HomeRepository {
  // ── Shared in-memory habit list ────────────────────────────────────────────
  // Static → one copy for the entire app session.
  // Mutable → CRUD operations work immediately without a real database.

  static final List<HabitDefinition> _habits = [
    const HabitDefinition(
      id: 'h1',
      title: 'Morning Run',
      category: HabitCategory.fitness,
      isDaily: true,
      goal: '5 km',
    ),
    const HabitDefinition(
      id: 'h2',
      title: 'Drink 2L Water',
      category: HabitCategory.hydration,
      isDaily: true,
      goal: '2L',
    ),
    const HabitDefinition(
      id: 'h3',
      title: 'Mindfulness',
      category: HabitCategory.mindfulness,
      isDaily: true,
      goal: '10 min',
    ),
    const HabitDefinition(
      id: 'h4',
      title: 'Read 20 Pages',
      category: HabitCategory.learning,
      isDaily: false,
      weekDays: [0, 1, 2, 3, 4], // Mon – Fri
      goal: '20 pages',
    ),
    const HabitDefinition(
      id: 'h5',
      title: 'Sleep 8 Hours',
      category: HabitCategory.sleep,
      isDaily: true,
      goal: '8 hrs',
    ),
  ];

  // ── Weekly completion pattern ──────────────────────────────────────────────
  // Keyed by habit id → 7 values [Mon … Sun], 1.0 = done, 0.0 = not done.
  // Stored as a static final (not const) so individual values can be toggled
  // when the user marks a habit complete on the home screen.

  static const Map<String, List<double>> _weeklyProgress = {
    'h1': [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0],
    'h2': [1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0],
    'h3': [1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0],
    'h4': [1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 0.0],
    'h5': [0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0],
  };

  // ── HomeRepository implementation ──────────────────────────────────────────

  @override
  Future<Map<DateTime, DaySummary>> getSummaryForWeek(
    DateTime weekStart,
  ) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final today = _dateOnly(DateTime.now());
    final result = <DateTime, DaySummary>{};

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final date = _dateOnly(weekStart.add(Duration(days: dayIndex)));
      final isFuture = date.isAfter(today);

      final habitsForDay = _habits.map((definition) {
        // Future dates always show 0 progress.
        final pattern = _weeklyProgress[definition.id];
        final progress =
            (isFuture || pattern == null) ? 0.0 : pattern[dayIndex];

        return HabitModel(
          id: definition.id,
          title: definition.title,
          subtitle: definition.subtitle,
          category: definition.category,
          isDaily: definition.isDaily,
          progress: progress,
        );
      }).toList();

      result[date] = DaySummary(date: date, habits: habitsForDay);
    }

    return result;
  }

  @override
  Future<List<HabitDefinition>> getAllHabits() async {
    await Future.delayed(const Duration(milliseconds: 150));
    // Return a copy so callers can't mutate the internal list directly.
    return List.unmodifiable(_habits);
  }

  @override
  Future<void> deleteHabit(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _habits.removeWhere((h) => h.id == id);
  }

  @override
  Future<void> updateHabit(HabitDefinition definition) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _habits.indexWhere((h) => h.id == definition.id);
    if (index != -1) _habits[index] = definition;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
