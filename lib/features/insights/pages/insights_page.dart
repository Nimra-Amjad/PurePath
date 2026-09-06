import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/insights/widgets/consistency_card.dart';
import 'package:purepath/features/insights/widgets/daily_completion_card.dart';
import 'package:purepath/features/insights/widgets/habit_matrix_card.dart';
import 'package:purepath/features/insights/widgets/habit_month_card.dart';
import 'package:purepath/features/insights/widgets/habit_year_card.dart';
import 'package:purepath/features/insights/widgets/insights_empty_view.dart';
import 'package:purepath/features/insights/widgets/month_navigator.dart';
import 'package:purepath/features/insights/widgets/month_stat_tiles.dart';
import 'package:purepath/features/insights/widgets/period_tabs.dart';
import 'package:purepath/features/insights/widgets/week_navigator.dart';
import 'package:purepath/features/insights/widgets/year_navigator.dart';
import 'package:purepath/features/insights/widgets/year_summary_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Insights page
//
// Reads from the global [InsightsBloc] (registered in DI) so toggles made on
// the home screen and habit edits made on the manage screen flow into the
// same instance. [InsightsStarted] is dispatched in initState so the latest
// data is fetched whenever the tab is mounted.
//
// The screen has three periods (Weekly / Monthly / Yearly). Only Weekly is
// built out; Monthly and Yearly show a placeholder for now.
// ─────────────────────────────────────────────────────────────────────────────

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  @override
  void initState() {
    super.initState();
    context.read<InsightsBloc>().add(InsightsStarted());
  }

  @override
  Widget build(BuildContext context) => const _InsightsView();
}

// ─────────────────────────────────────────────────────────────────────────────
// Insights view — reads from [InsightsBloc]
// ─────────────────────────────────────────────────────────────────────────────

class _InsightsView extends StatelessWidget {
  const _InsightsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InsightsBloc, InsightsState>(
      builder: (context, state) {
        if (state.status == InsightsStatus.loading) {
          return const _LoadingView();
        }

        if (state.status == InsightsStatus.error) {
          return _ErrorView(
            message: state.errorMessage ?? 'Something went wrong.',
          );
        }

        return _LoadedView(state: state);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loaded view — holds the selected period so switching tabs is instant.
// ─────────────────────────────────────────────────────────────────────────────

class _LoadedView extends StatefulWidget {
  final InsightsState state;
  const _LoadedView({required this.state});

  @override
  State<_LoadedView> createState() => _LoadedViewState();
}

class _LoadedViewState extends State<_LoadedView> {
  InsightsPeriod _period = InsightsPeriod.weekly;

  InsightsState get state => widget.state;

  void _onPrevWeek() {
    context.read<InsightsBloc>().add(
      InsightsWeekChanged(
        state.visibleWeekStart.subtract(const Duration(days: 7)),
      ),
    );
  }

  void _onNextWeek() {
    context.read<InsightsBloc>().add(
      InsightsWeekChanged(state.visibleWeekStart.add(const Duration(days: 7))),
    );
  }

  void _onPrevMonth() {
    final m = state.visibleMonthStart;
    context.read<InsightsBloc>().add(
      InsightsMonthChanged(DateTime(m.year, m.month - 1, 1)),
    );
  }

  void _onNextMonth() {
    final m = state.visibleMonthStart;
    context.read<InsightsBloc>().add(
      InsightsMonthChanged(DateTime(m.year, m.month + 1, 1)),
    );
  }

  void _onPrevYear() {
    context.read<InsightsBloc>().add(
      InsightsYearChanged(state.visibleYear - 1),
    );
  }

  void _onNextYear() {
    context.read<InsightsBloc>().add(
      InsightsYearChanged(state.visibleYear + 1),
    );
  }

  void _onPeriodChanged(InsightsPeriod p) {
    setState(() => _period = p);
    // The yearly grids need a full year of history; the initial load only
    // fetches a few months, so ensure it's loaded when the tab opens.
    if (p == InsightsPeriod.yearly) {
      context.read<InsightsBloc>().add(InsightsYearChanged(state.visibleYear));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Space.vertical(4),

          // ── Page title ──────────────────────────────────────────────────
          Text(
            'Insights',
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 26,
              color: kWhiteColor,
            ),
          ),
          Space.vertical(16),

          // ── Period tabs ─────────────────────────────────────────────────
          PeriodTabs(selected: _period, onChanged: _onPeriodChanged),
          Space.vertical(20),

          // ── Period body ─────────────────────────────────────────────────
          if (_period == InsightsPeriod.weekly)
            _WeeklyBody(
              state: state,
              onPrevWeek: _onPrevWeek,
              onNextWeek: _onNextWeek,
            )
          else if (_period == InsightsPeriod.monthly)
            _MonthlyBody(
              state: state,
              onPrevMonth: _onPrevMonth,
              onNextMonth: _onNextMonth,
            )
          else
            _YearlyBody(
              state: state,
              onPrevYear: _onPrevYear,
              onNextYear: _onNextYear,
            ),

          Space.vertical(20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekly body — the full weekly overview.
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyBody extends StatelessWidget {
  final InsightsState state;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;

  const _WeeklyBody({
    required this.state,
    required this.onPrevWeek,
    required this.onNextWeek,
  });

  @override
  Widget build(BuildContext context) {
    // No habits → nothing to chart. Show the welcoming onboarding view.
    if (state.habits.isEmpty) {
      return const InsightsEmptyView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Week navigator ──────────────────────────────────────────────
        WeekNavigator(
          weekStart: state.visibleWeekStart,
          weekEnd: state.visibleWeekEnd,
          onPrevWeek: onPrevWeek,
          onNextWeek: onNextWeek,
        ),
        Space.vertical(20),

        // ── Consistency ─────────────────────────────────────────────────
        ConsistencyCard(
          consistency: state.weekConsistency,
          completed: state.weekCompletedCount,
          scheduled: state.weekScheduledCount,
          deltaPoints: state.consistencyDeltaPoints,
        ),
        Space.vertical(16),

        // ── Daily completion bars ───────────────────────────────────────
        DailyCompletionCard(
          summaries: state.visibleWeekSummaries,
          trackedHabitCount: state.trackedHabitCount,
        ),
        Space.vertical(16),

        // ── Per-habit weekly matrix ─────────────────────────────────────
        HabitMatrixCard(
          habits: state.habits,
          history: state.completionHistory,
          weekStart: state.visibleWeekStart,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Monthly body — the full monthly overview.
// ─────────────────────────────────────────────────────────────────────────────

class _MonthlyBody extends StatelessWidget {
  final InsightsState state;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const _MonthlyBody({
    required this.state,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    // No habits → nothing to chart. Show the welcoming onboarding view.
    if (state.habits.isEmpty) {
      return const InsightsEmptyView();
    }

    final habitStats = state.habitMonthStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Month navigator ─────────────────────────────────────────────
        MonthNavigator(
          monthStart: state.visibleMonthStart,
          onPrevMonth: onPrevMonth,
          onNextMonth: onNextMonth,
        ),
        Space.vertical(20),

        // ── Summary tiles ───────────────────────────────────────────────
        MonthStatTiles(
          metPercent: (state.monthMet * 100).round(),
          daysDone: state.monthCompletedCount,
          perfect: state.monthPerfectHabits,
        ),
        Space.vertical(16),

        // ── Per-habit calendars ─────────────────────────────────────────
        for (var i = 0; i < habitStats.length; i++) ...[
          HabitMonthCard(
            stat: habitStats[i],
            history: state.completionHistory,
            monthStart: state.visibleMonthStart,
          ),
          if (i != habitStats.length - 1) Space.vertical(16),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yearly body — the full yearly overview.
// ─────────────────────────────────────────────────────────────────────────────

class _YearlyBody extends StatelessWidget {
  final InsightsState state;
  final VoidCallback onPrevYear;
  final VoidCallback onNextYear;

  const _YearlyBody({
    required this.state,
    required this.onPrevYear,
    required this.onNextYear,
  });

  @override
  Widget build(BuildContext context) {
    // No habits → nothing to chart. Show the welcoming onboarding view.
    if (state.habits.isEmpty) {
      return const InsightsEmptyView();
    }

    final habitStats = state.habitYearStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Year navigator ──────────────────────────────────────────────
        YearNavigator(
          year: state.visibleYear,
          onPrevYear: onPrevYear,
          onNextYear: onNextYear,
        ),
        Space.vertical(20),

        // ── Summary ─────────────────────────────────────────────────────
        YearSummaryCard(
          year: state.visibleYear,
          daysCompleted: state.yearDaysCompleted,
        ),
        Space.vertical(16),

        // ── Per-habit year grids ────────────────────────────────────────
        for (var i = 0; i < habitStats.length; i++) ...[
          HabitYearCard(
            stat: habitStats[i],
            history: state.completionHistory,
            year: state.visibleYear,
          ),
          if (i != habitStats.length - 1) Space.vertical(16),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading view
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: kPrimaryGreenColor),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: kRedColor, size: 48),
            Space.vertical(12),
            Text(
              message,
              style: AppTextStyles.normal.copyWith(color: kLightGreyColor),
              textAlign: TextAlign.center,
            ),
            Space.vertical(16),
            ElevatedButton(
              onPressed: () =>
                  context.read<InsightsBloc>().add(InsightsStarted()),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreenColor,
                foregroundColor: kBlackColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
