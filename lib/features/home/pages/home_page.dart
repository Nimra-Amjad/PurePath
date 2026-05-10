import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/bloc/home_bloc.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/features/home/widgets/daily_progress_card.dart';
import 'package:purepath/features/home/widgets/habit_tile_widget.dart';
import 'package:purepath/features/home/widgets/home_header_widget.dart';
import 'package:purepath/features/home/widgets/horizontal_calendar_widget.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/notifications/bloc/notification_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home page
//
// Reads from the global [HomeBloc] (registered in DI) and dispatches
// [HomeStarted] in initState so the latest habits are fetched every time
// the home tab is mounted (e.g. after login or after creating a habit).
// ─────────────────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeStarted());
    // Sync reminders for the current user. NotificationBloc also fires this
    // once at app start, but auth may not have settled yet at that point —
    // getAllHabits() would return an empty list. Re-syncing on home mount
    // covers fresh-login and post-onboarding cases.
    context.read<NotificationBloc>().add(const HabitNotificationsSynced());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ─────────────────────────────────────────────────
              const HomeHeaderWidget(),
              Space.vertical(20),

              // ── Weekly calendar ───────────────────────────────────────────
              TrainingCalendar(
                weekData: state.weekData,
                selectedDate: state.selectedDate,
                visibleWeekStart: state.visibleWeekStart,
                onDateSelected: (date) {
                  context.read<HomeBloc>().add(HomeDateSelected(date));
                },
                onWeekChanged: (weekStart) {
                  context.read<HomeBloc>().add(HomeWeekChanged(weekStart));
                },
              ),

              Space.vertical(20),

              // ── Content below calendar ────────────────────────────────────
              _buildContent(context, state),

              Space.vertical(24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, HomeState state) {
    switch (state.status) {
      case HomeStatus.loading:
        return const _LoadingView();

      case HomeStatus.error:
        return _ErrorView(
          message: state.errorMessage ?? 'Something went wrong',
        );

      case HomeStatus.loaded:
        final summary = state.selectedDaySummary;

        // Summary missing means the user swiped to a week that's still loading.
        if (summary == null) return const _LoadingView();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DailyProgressCard(summary: summary),
            Space.vertical(20),

            // ── Section header ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Habits",
                  style: AppTextStyles.semiBold.copyWith(fontSize: 16),
                ),
                GestureDetector(
                  onTap: () => AppRoute.manageHabits.push(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: AppTextStyles.medium.copyWith(
                          fontSize: 13,
                          color: purple,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: purple,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Space.vertical(12),

            // ── Habit tiles ─────────────────────────────────────────────
            if (summary.habits.isEmpty)
              const _EmptyHabitsView()
            else
              ...summary.habits.map(
                (habit) => HabitTileWidget(
                  habit: habit,
                  onTap: () {
                    context.read<HomeBloc>().add(HabitToggled(habit.id));
                    // Keep insights in sync — its weekly stats depend on
                    // the same completion record we just toggled.
                    context
                        .read<InsightsBloc>()
                        .add(InsightsRefreshRequested());
                  },
                ),
              ),
          ],
        );
    }
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
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: CircularProgressIndicator(color: purple),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty habits view — shown when the user hasn't created any habits yet.
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyHabitsView extends StatelessWidget {
  const _EmptyHabitsView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGreyColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 32)),
          Space.vertical(10),
          Text(
            'No habits yet',
            style: AppTextStyles.semiBold.copyWith(fontSize: 15),
          ),
          Space.vertical(6),
          Text(
            'Tap the + button to create your first habit.',
            textAlign: TextAlign.center,
            style: AppTextStyles.normal.copyWith(
              fontSize: 13,
              color: kDarkGreyColor,
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            Space.vertical(12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.normal.copyWith(color: kDarkGreyColor),
            ),
            Space.vertical(16),
            TextButton(
              onPressed: () =>
                  context.read<HomeBloc>().add(HomeStarted()),
              child: Text(
                'Retry',
                style: AppTextStyles.medium.copyWith(color: purple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
