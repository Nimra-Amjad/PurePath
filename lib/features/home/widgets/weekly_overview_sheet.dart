import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/day_summary.dart';
import 'package:purepath/features/home/models/habit_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Weekly overview sheet
//
// Opened from the calendar icon in the "This Week" header. Shows one card per
// habit scheduled during the visible week, each with a Mon → Sun row of day
// circles:
//
//   • filled lime  → completed that day
//   • lime border  → today, still open
//   • faint border → scheduled but missed (past) / still to come (future)
//   • dimmed       → habit wasn't scheduled that day
//
// Pure UI: it's handed the already-loaded [weekData] from HomeState, so it
// triggers no extra fetch. Weekly habits only appear on their scheduled days
// (a day is "scheduled" when the habit shows up in that day's [DaySummary]).
// ─────────────────────────────────────────────────────────────────────────────

class WeeklyOverviewSheet extends StatelessWidget {
  /// Monday of the week being shown (local midnight).
  final DateTime weekStart;

  /// All cached day summaries from HomeState. Only the 7 days of [weekStart]
  /// are read; missing days render as "not scheduled".
  final Map<DateTime, DaySummary> weekData;

  const WeeklyOverviewSheet({
    super.key,
    required this.weekStart,
    required this.weekData,
  });

  /// Opens the overview for the week starting at [weekStart].
  static Future<void> show(
    BuildContext context, {
    required DateTime weekStart,
    required Map<DateTime, DaySummary> weekData,
  }) {
    return AppBottomSheet.show(
      context,
      body: WeeklyOverviewSheet(weekStart: weekStart, weekData: weekData),
    );
  }

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// "Aug 18 – 24" (or "Jul 30 – Aug 5" when the week spans two months).
  String get _rangeLabel {
    final start = weekStart;
    final end = weekStart.add(const Duration(days: 6));
    final startLabel = '${_monthNames[start.month - 1]} ${start.day}';
    final endLabel = start.month == end.month
        ? '${end.day}'
        : '${_monthNames[end.month - 1]} ${end.day}';
    return '$startLabel – $endLabel';
  }

  /// Groups the week's per-day summaries into one [_HabitWeek] per habit,
  /// preserving first-seen order.
  List<_HabitWeek> _buildHabitWeeks() {
    final Map<String, _HabitWeek> byId = {};
    final order = <String>[];

    for (var i = 0; i < 7; i++) {
      final date = _dateOnly(weekStart.add(Duration(days: i)));
      final summary = weekData[date];
      if (summary == null) continue;
      for (final habit in summary.habits) {
        final week = byId.putIfAbsent(habit.id, () {
          order.add(habit.id);
          return _HabitWeek(habit: habit);
        });
        week.days[i] = habit.isCompleted ? _DayState.done : _DayState.scheduled;
      }
    }

    return order.map((id) => byId[id]!).toList();
  }

  @override
  Widget build(BuildContext context) {
    final habitWeeks = _buildHabitWeeks();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: kPrimaryGreenColor.withOpacityValue(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: kPrimaryGreenColor,
                  size: 20,
                ),
              ),
              Space.horizontal(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Overview',
                      style: AppTextStyles.semiBold.copyWith(
                        fontSize: 17,
                        color: kWhiteColor,
                      ),
                    ),
                    Text(
                      _rangeLabel,
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 13,
                        color: kLightGreyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Space.vertical(20),

          // ── Habit cards (or empty state) ───────────────────────────────
          if (habitWeeks.isEmpty)
            const _EmptyState()
          else
            ...habitWeeks.map(
              (hw) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _HabitWeekCard(weekStart: weekStart, habitWeek: hw),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-day state for one habit within the week.
// ─────────────────────────────────────────────────────────────────────────────

enum _DayState {
  /// Habit wasn't scheduled that day.
  off,

  /// Scheduled that day, not (yet) completed.
  scheduled,

  /// Scheduled and completed.
  done,
}

/// One habit's 7-day slice. [days] is indexed Mon(0) → Sun(6).
class _HabitWeek {
  final HabitModel habit;
  final List<_DayState> days = List.filled(7, _DayState.off);

  _HabitWeek({required this.habit});

  /// Days scheduled up to and including today (future days excluded from the
  /// denominator so the ratio reads "done so far", not "done out of the whole
  /// week including days that haven't happened").
  int scheduledSoFar(DateTime weekStart, DateTime today) {
    var count = 0;
    for (var i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final past = !date.isAfter(today);
      if (days[i] != _DayState.off && past) count++;
    }
    return count;
  }

  int get completedCount => days.where((d) => d == _DayState.done).length;
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit week card — emoji + title, Mon→Sun circles, footer stats.
// ─────────────────────────────────────────────────────────────────────────────

class _HabitWeekCard extends StatelessWidget {
  final DateTime weekStart;
  final _HabitWeek habitWeek;

  const _HabitWeekCard({required this.weekStart, required this.habitWeek});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final habit = habitWeek.habit;
    final today = _today();
    final scheduled = habitWeek.scheduledSoFar(weekStart, today);
    final done = habitWeek.completedCount;
    final percent = scheduled == 0 ? 0 : ((done / scheduled) * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: emoji + title  ···  frequency ──────────────────────
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kHabitAccentColor.withOpacityValue(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  kHabitEmoji,
                  style: TextStyle(fontSize: 17),
                ),
              ),
              Space.horizontal(10),
              Expanded(
                child: Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 15,
                    color: kWhiteColor,
                  ),
                ),
              ),
              Space.horizontal(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kPrimaryGreenColor.withOpacityValue(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  habit.frequencyLabel,
                  style: AppTextStyles.medium.copyWith(
                    fontSize: 11,
                    color: kPrimaryGreenColor,
                  ),
                ),
              ),
            ],
          ),
          Space.vertical(16),

          // ── Mon → Sun day circles ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final date = weekStart.add(Duration(days: i));
              return _DayCircle(
                label: _dayLabels[i],
                dayNumber: date.day,
                state: habitWeek.days[i],
                isToday: DateUtils.isSameDay(date, today),
                isFuture: date.isAfter(today),
              );
            }),
          ),
          Space.vertical(14),
          Divider(color: kLightGreyColor.withOpacityValue(0.12), height: 1),
          Space.vertical(12),

          // ── Footer: streak-style count + completion % ──────────────────
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: kPrimaryGreenColor,
                size: 16,
              ),
              Space.horizontal(6),
              Text(
                '$done of $scheduled done',
                style: AppTextStyles.medium.copyWith(
                  fontSize: 12.5,
                  color: kLightGreyColor,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: AppTextStyles.semiBold.copyWith(
                  fontSize: 13,
                  color: kPrimaryGreenColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One day cell — weekday label + circle with the date number.
// ─────────────────────────────────────────────────────────────────────────────

class _DayCircle extends StatelessWidget {
  final String label;
  final int dayNumber;
  final _DayState state;
  final bool isToday;
  final bool isFuture;

  const _DayCircle({
    required this.label,
    required this.dayNumber,
    required this.state,
    required this.isToday,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    final done = state == _DayState.done;
    final scheduled = state != _DayState.off;

    Color fill = kTransparentColor;
    Color textColor = kWhiteColor;
    Color borderColor = kTransparentColor;

    if (done) {
      // Completed — solid lime pill, dark text.
      fill = kPrimaryGreenColor;
      textColor = kBlackColor;
      borderColor = kPrimaryGreenColor;
    } else if (!scheduled) {
      // Not scheduled that day — dim, no border.
      textColor = kLightGreyColor.withOpacityValue(0.35);
    } else if (isToday) {
      // Today, still open — highlighted lime ring.
      borderColor = kPrimaryGreenColor;
      textColor = kPrimaryGreenColor;
    } else if (isFuture) {
      // Scheduled but not here yet — faint ring.
      borderColor = kLightGreyColor.withOpacityValue(0.3);
      textColor = kLightGreyColor.withOpacityValue(0.7);
    } else {
      // Scheduled in the past but missed — muted ring.
      borderColor = kLightGreyColor.withOpacityValue(0.4);
      textColor = kLightGreyColor;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.medium.copyWith(
            fontSize: 11,
            color: isToday
                ? kPrimaryGreenColor
                : kLightGreyColor.withOpacityValue(0.8),
          ),
        ),
        Space.vertical(6),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Text(
            '$dayNumber',
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 13,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — no habits scheduled for the visible week.
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_busy_rounded,
              color: kLightGreyColor.withOpacityValue(0.6),
              size: 40,
            ),
            Space.vertical(12),
            Text(
              'No habits scheduled this week',
              style: AppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kLightGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
