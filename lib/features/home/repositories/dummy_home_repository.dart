import 'package:purepath/features/home/models/day_summary.dart';
import 'package:purepath/features/home/models/habit_model.dart';
import 'package:purepath/features/home/repositories/home_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dummy home repository
//
// Returns hard-coded but realistic habit data so the UI looks meaningful
// before Firestore is connected.
//
// SWAP GUIDE: Replace DummyHomeRepository() with FirestoreHomeRepository()
// in home_page.dart's BlocProvider — nothing else needs to change.
// ─────────────────────────────────────────────────────────────────────────────

class DummyHomeRepository implements HomeRepository {
  // ── Habit templates ────────────────────────────────────────────────────────
  // Simulates the habits a user has created. In production this list
  // comes from Firestore (the user's habits collection).

  static const _habits = [
    _HabitTemplate(
      id: 'h1',
      title: 'Morning Run',
      subtitle: '5 km · Fitness',
      category: HabitCategory.fitness,
    ),
    _HabitTemplate(
      id: 'h2',
      title: 'Drink 2L Water',
      subtitle: '2L · Hydration',
      category: HabitCategory.hydration,
    ),
    _HabitTemplate(
      id: 'h3',
      title: 'Mindfulness',
      subtitle: '10 min · Mindfulness',
      category: HabitCategory.mindfulness,
    ),
    _HabitTemplate(
      id: 'h4',
      title: 'Read 20 Pages',
      subtitle: '20 pages · Learning',
      category: HabitCategory.learning,
    ),
    _HabitTemplate(
      id: 'h5',
      title: 'Sleep 8 Hours',
      subtitle: '8 hrs · Sleep',
      category: HabitCategory.sleep,
    ),
  ];

  // ── Weekly progress pattern ────────────────────────────────────────────────
  // Each inner list = one day (Mon → Sun), each value maps to a habit above.
  // Gives realistic variety across the week.

  static const _weeklyProgress = [
    [1.0, 1.0, 0.0, 0.0, 0.0], // Monday   — 2/5 done
    [1.0, 1.0, 1.0, 1.0, 1.0], // Tuesday  — perfect day
    [1.0, 0.0, 1.0, 0.0, 0.0], // Wednesday — 2/5 done
    [1.0, 1.0, 1.0, 1.0, 0.0], // Thursday — 4/5 done
    [1.0, 1.0, 0.0, 0.0, 0.0], // Friday   — 2/5 done
    [1.0, 0.0, 0.0, 0.0, 0.0], // Saturday — 1/5 done
    [0.0, 0.0, 0.0, 0.0, 0.0], // Sunday   — rest day
  ];

  // ── HomeRepository implementation ──────────────────────────────────────────

  @override
  Future<Map<DateTime, DaySummary>> getSummaryForWeek(
    DateTime weekStart,
  ) async {
    // Simulate a short network delay — remove when Firestore is connected.
    await Future.delayed(const Duration(milliseconds: 250));

    final today = _dateOnly(DateTime.now());
    final result = <DateTime, DaySummary>{};

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final date = _dateOnly(weekStart.add(Duration(days: dayIndex)));
      final isFuture = date.isAfter(today);

      final habits = _habits.asMap().entries.map((entry) {
        final template = entry.value;
        // Future dates always show 0 progress.
        final progress = isFuture ? 0.0 : _weeklyProgress[dayIndex][entry.key];

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
// Internal template — keeps the habits list above readable
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
