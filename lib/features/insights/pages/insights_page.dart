import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/insights/widgets/bar_chat_widget.dart';
import 'package:purepath/features/insights/widgets/barchart_calendar_widget.dart';
import 'package:purepath/features/insights/widgets/progress_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Insights page
//
// Reads from the global [InsightsBloc] (registered in DI) so toggles made on
// the home screen and habit edits made on the manage screen flow into the
// same instance. [InsightsStarted] is dispatched in initState so the latest
// data is fetched whenever the tab is mounted.
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
// Loaded view
// ─────────────────────────────────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  final InsightsState state;
  const _LoadedView({required this.state});

  void _onPrevWeek(BuildContext context) {
    context.read<InsightsBloc>().add(
      InsightsWeekChanged(
        state.visibleWeekStart.subtract(const Duration(days: 7)),
      ),
    );
  }

  void _onNextWeek(BuildContext context) {
    context.read<InsightsBloc>().add(
      InsightsWeekChanged(state.visibleWeekStart.add(const Duration(days: 7))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = state.habitWeeklyStats;
    final summaries = state.visibleWeekSummaries;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page title ───────────────────────────────────────────────────
          Text(
            'Insights',
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 24,
              color: kWhiteColor,
            ),
          ),
          Space.vertical(20),

          // ── Week navigator ───────────────────────────────────────────────
          BarchartCalendarWidget(
            weekStart: state.visibleWeekStart,
            weekEnd: state.visibleWeekEnd,
            onPrevWeek: () => _onPrevWeek(context),
            onNextWeek: () => _onNextWeek(context),
          ),
          Space.vertical(20),

          // ── Bar chart ────────────────────────────────────────────────────
          BarChartWidget(summaries: summaries),
          Space.vertical(24),

          // ── Per-habit weekly stats ───────────────────────────────────────
          if (stats.isNotEmpty) ...[
            Text(
              'Habit Progress',
              style: AppTextStyles.semiBold.copyWith(fontSize: 16),
            ),
            Space.vertical(12),
            ...stats.map(
              (stat) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ProgressWidget(stat: stat),
              ),
            ),
          ],

          Space.vertical(20),
        ],
      ),
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
    return const Center(child: CircularProgressIndicator(color: purple));
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
            const Icon(Icons.error_outline, color: red, size: 48),
            Space.vertical(12),
            Text(
              message,
              style: AppTextStyles.normal.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
            Space.vertical(16),
            ElevatedButton(
              onPressed: () =>
                  context.read<InsightsBloc>().add(InsightsStarted()),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: kWhiteColor,
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
