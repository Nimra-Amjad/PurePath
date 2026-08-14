import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/app_dialog.dart';
import 'package:purepath/core/widgets/custom_error_view.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/bloc/home_bloc.dart';
import 'package:purepath/features/home/bloc/manage_habits_bloc.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/repositories/user_repository.dart';
import 'package:purepath/features/home/widgets/daily_progress_card.dart';
import 'package:purepath/features/home/widgets/first_completion_dialog.dart';
import 'package:purepath/features/home/widgets/empty_habit_view.dart';
import 'package:purepath/features/home/widgets/no_habit_for_day_view.dart';
import 'package:purepath/features/home/widgets/habit_tile_widget.dart';
import 'package:purepath/features/home/widgets/home_header_widget.dart';
import 'package:purepath/features/home/widgets/horizontal_calendar_widget.dart';
import 'package:purepath/features/home/widgets/streak_restore_banner.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/notifications/bloc/notification_bloc.dart';
import 'package:purepath/features/paywall/bloc/subscription_bloc.dart';
import 'package:purepath/features/paywall/utils/habit_limit_gate.dart';

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
    // Load the full habit list too so the empty state can tell "no habits at
    // all" apart from "habits exist, just none scheduled for this day".
    context.read<ManageHabitsBloc>().add(ManageHabitsStarted());
    // Sync reminders for the current user. NotificationBloc also fires this
    // once at app start, but auth may not have settled yet at that point —
    // getAllHabits() would return an empty list. Re-syncing on home mount
    // covers fresh-login and post-onboarding cases.
    context.read<NotificationBloc>().add(const HabitNotificationsSynced());
  }

  /// Restore is Pro-only: Pro users repair the streak immediately, everyone
  /// else is sent to the paywall to subscribe first.
  void _onRestoreStreak(BuildContext context) {
    final isPro = context.read<SubscriptionBloc>().state.isPro;
    if (isPro) {
      context.read<HomeBloc>().add(StreakRestoreRequested());
    } else {
      AppRoute.paywall.push(context);
    }
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

              // ── Streak restore (Pro) ──────────────────────────────────────
              if (state.restorableBreak != null) ...[
                StreakRestoreBanner(
                  recoveredStreak: state.restorableBreak!.recoveredStreak,
                  onRestore: () => _onRestoreStreak(context),
                ),
                Space.vertical(20),
              ],

              // ── Explore habit library entry ───────────────────────────────
              const _HabitLibraryBanner(),
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
        return CustomErrorView(
          message: state.errorMessage ?? 'Something went wrong',
          onRetry: () {
            context.read<HomeBloc>().add(HomeStarted());
          },
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
              children: [
                Expanded(
                  child: Text(
                    "Today's Habits",
                    style: AppTextStyles.semiBold.copyWith(
                      fontSize: 16,
                      color: kWhiteColor,
                    ),
                  ),
                ),
                if (summary.habits.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => AppRoute.habits.push(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: AppTextStyles.medium.copyWith(
                            fontSize: 13,
                            color: kPrimaryGreenColor,
                          ),
                        ),
                        Space.horizontal(4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: kPrimaryGreenColor,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                  Space.horizontal(12),

                  // Quick "add habit" entry — jumps straight to the create form
                  // (or the paywall once the free habit limit is reached).
                  GestureDetector(
                    onTap: () => openAddHabitGated(context),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: kPrimaryGreenColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: kBlackColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Space.vertical(12),

            // ── Habit tiles ─────────────────────────────────────────────
            if (summary.habits.isEmpty)
              _buildEmptyState(context)
            else
              ...summary.habits.map(
                (habit) => HabitTileWidget(
                  key: ValueKey(habit.id),
                  habit: habit,
                  onTap: () async {
                    final home = context.read<HomeBloc>();
                    final insights = context.read<InsightsBloc>();
                    final userRepo = context.read<UserRepository>();
                    // The new state is the opposite of the current one.
                    final nowCompleted = !habit.isCompleted;

                    // Guard against accidental un-marking: a completed habit
                    // asks for confirmation before its completion is removed.
                    // Blocs are captured above so no BuildContext is used
                    // across the await.
                    if (!nowCompleted) {
                      final confirmed = await AppDialog.show(
                        context,
                        icon: Icons.undo_rounded,
                        iconColor: red,
                        title: 'Unmark habit?',
                        subtitle:
                            'This removes today\'s completion for '
                            '"${habit.title}".',
                        confirmText: 'Unmark',
                        confirmColor: red,
                      );
                      if (confirmed != true) return;
                    }

                    home.add(HabitToggled(habit.id));
                    // Mirror the toggle into insights in memory so the dot /
                    // weekly stats update instantly. An in-place update (not a
                    // re-fetch) avoids racing the Firestore write home just
                    // started — the read could otherwise return the old value
                    // and leave the dot a toggle behind.
                    insights.add(
                      InsightsCompletionToggled(
                        habitId: habit.id,
                        date: home.state.selectedDate,
                        completed: nowCompleted,
                      ),
                    );

                    // First-ever completion → one-time motivational popup.
                    // The flag is persisted so it only ever shows once; the
                    // write is fire-and-forget so nothing is blocked.
                    if (nowCompleted &&
                        userRepo.localUser?.hasCelebratedFirstCompletion ==
                            false) {
                      unawaited(userRepo.markFirstCompletionCelebrated());
                      // Let the completion animation land first, then celebrate
                      // right after so the reward stays tied to the tap.
                      await Future.delayed(const Duration(milliseconds: 800));
                      if (!context.mounted) return;
                      await FirstCompletionDialog.show(context);
                    }
                  },
                ),
              ),
          ],
        );
    }
  }

  /// Chooses which empty state to show when the selected day has no habits:
  ///   • no habits at all      → [EmptyHabitView] (create-your-first-habit)
  ///   • habits exist, none today → [NoHabitForDayView] (informational)
  Widget _buildEmptyState(BuildContext context) {
    final manage = context.watch<ManageHabitsBloc>().state;

    // Full list still loading — hold off so we don't flash the wrong view.
    if (manage.status == ManageHabitsStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: kPrimaryGreenColor),
        ),
      );
    }

    return manage.habits.isEmpty
        ? const EmptyHabitView()
        : const NoHabitForDayView();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit library banner
//
// Tappable entry point on the home screen that opens the category-tabbed
// Habit Library (suggested habits grouped by intensity level).
// ─────────────────────────────────────────────────────────────────────────────

class _HabitLibraryBanner extends StatelessWidget {
  const _HabitLibraryBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppRoute.exploreHabits.push(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kContainerColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimaryGreenColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimaryGreenColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: kPrimaryGreenColor,
                size: 22,
              ),
            ),
            Space.horizontal(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore Habit Library',
                    style: AppTextStyles.semiBold.copyWith(
                      fontSize: 15,
                      color: kWhiteColor,
                    ),
                  ),
                  Space.vertical(2),
                  Text(
                    'Browse habits by category & level',
                    style: AppTextStyles.normal.copyWith(
                      fontSize: 12,
                      color: kLightGreyColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: kPrimaryGreenColor,
              size: 14,
            ),
          ],
        ),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: CircularProgressIndicator(color: kPrimaryGreenColor),
      ),
    );
  }
}
