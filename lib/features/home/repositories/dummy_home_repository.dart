import 'package:purepath/features/home/models/day_summary.dart';
import 'package:purepath/features/home/models/habit_model.dart';
import 'package:purepath/features/home/repositories/home_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dummy home repository
//
// Returns hard-coded but realistic habit data so the UI looks meaningful
// before Firestore is connected.
//
// SWAP GUIDE: Replace this with FirestoreHomeRepository in di.dart.
// Everything else (HomeBloc, widgets, HomePage) stays the same.
// ─────────────────────────────────────────────────────────────────────────────

class DummyHomeRepository implements HomeRepository {
  // ── Habit templates ────────────────────────────────────────────────────────
  // These represent the user's recurring habits. In production, this list
  // would come from Firestore (user's habit collection).

  static const _habits = [
    _HabitTemplate(
      id: 'h1',
      title: 'Morning Meditation',
      subtitle: '10 min · Body & Mind',
      category: HabitCategory.meditation,
    ),
    _HabitTemplate(
      id: 'h2',
      title: 'Read 20 Pages',
      subtitle: '20 pages · Learning',
      category: HabitCategory.reading,
    ),
    _HabitTemplate(
      id: 'h3',
      title: 'Drink 2L Water',
      subtitle: '2L · Health',
      category: HabitCategory.hydration,
    ),
    _HabitTemplate(
      id: 'h4',
      title: 'Evening Run',
      subtitle: '5 km · Fitness',
      category: HabitCategory.fitness,
    ),
    _HabitTemplate(
      id: 'h5',
      title: 'Journaling',
      subtitle: '5 min · Reflection',
      category: HabitCategory.journaling,
    ),
  ];

  // ── Weekly progress pattern ────────────────────────────────────────────────
  // Each inner list is one day (Mon→Sun), each value maps to a habit above.
  // This gives realistic variety: some great days, some slow days.

  static const _weeklyProgress = [
    [1.0, 1.0, 0.6, 0.0, 0.0], // Monday   — good start, incomplete evening
    [1.0, 1.0, 1.0, 0.8, 1.0], // Tuesday  — almost perfect
    [1.0, 0.4, 0.5, 0.0, 0.0], // Wednesday — slow mid-week
    [1.0, 1.0, 0.9, 1.0, 0.0], // Thursday — strong, missed journaling
    [1.0, 0.2, 0.3, 0.0, 0.0], // Friday   — partial effort
    [0.5, 0.0, 0.7, 0.0, 0.0], // Saturday — weekend mode
    [0.0, 0.0, 0.0, 0.0, 0.0], // Sunday   — rest day
  ];

  // ── HomeRepository implementation ─────────────────────────────────────────

  @override
  Future<Map<DateTime, DaySummary>> getSummaryForWeek(
    DateTime weekStart,
  ) async {
    // Simulate a short network delay (remove when using real Firestore).
    await Future.delayed(const Duration(milliseconds: 250));

    final today = _dateOnly(DateTime.now());
    final result = <DateTime, DaySummary>{};

    for (int i = 0; i < 7; i++) {
      final date = _dateOnly(weekStart.add(Duration(days: i)));
      final isFuture = date.isAfter(today);

      final habits = _habits.asMap().entries.map((entry) {
        // Future dates always show 0 progress.
        final progress = isFuture ? 0.0 : _weeklyProgress[i][entry.key];
        final template = entry.value;

        return HabitModel(
          id: template.id,
          title: template.title,
          subtitle: template.subtitle,
          category: template.category,
          progress: progress,
        );
      }).toList();

      result[date] = DaySummary(date: date, habits: habits);
    }

    return result;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helper — keeps the template list readable
// ─────────────────────────────────────────────────────────────────────────────

class _HabitTemplate {
  final String id;
  final String title;
  final String subtitle;
  final HabitCategory category;

  const _HabitTemplate({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
  });
}
