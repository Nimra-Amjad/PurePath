import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/widgets/app_dialog.dart';
import 'package:purepath/core/widgets/custom_error_view.dart';
import 'package:purepath/core/widgets/rounded_back_button.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/features/home/bloc/home_bloc.dart';
import 'package:purepath/features/home/bloc/manage_habits_bloc.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/core/repositories/home_repository.dart';
import 'package:purepath/features/home/widgets/empty_habit_view.dart';
import 'package:purepath/features/home/widgets/manage_habit_tile_widget.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/notifications/bloc/notification_bloc.dart';
import 'package:purepath/features/paywall/utils/habit_limit_gate.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Manage habits page
//
// Reads from the global [ManageHabitsBloc] (registered in DI) and dispatches
// [ManageHabitsStarted] in initState so the latest list is fetched every
// time the page is opened.
// ─────────────────────────────────────────────────────────────────────────────

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ManageHabitsBloc>().add(ManageHabitsStarted());
  }

  @override
  Widget build(BuildContext context) => const _ManageHabitsView();
}

// ─────────────────────────────────────────────────────────────────────────────
// View — reads ManageHabitsBloc
// ─────────────────────────────────────────────────────────────────────────────

class _ManageHabitsView extends StatelessWidget {
  const _ManageHabitsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: _buildAppBar(context),
      body: BlocBuilder<ManageHabitsBloc, ManageHabitsState>(
        builder: (context, state) {
          return switch (state.status) {
            ManageHabitsStatus.loading => const _LoadingView(),
            ManageHabitsStatus.error => CustomErrorView(
              message: state.errorMessage ?? 'Something went wrong.',
              onRetry: () {
                context.read<ManageHabitsBloc>().add(ManageHabitsStarted());
              },
            ),
            ManageHabitsStatus.loaded => _LoadedView(habits: state.habits),
          };
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: kScaffoldColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: RoundedBackButton(
            onTap: () {
              context.pop();
            },
          ),
        ),
      ),
      leadingWidth: 60,
      title: Text(
        'My Habits',
        style: AppTextStyles.bold.copyWith(fontSize: 20, color: kWhiteColor),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loaded view — list of habit tiles
// ─────────────────────────────────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  final List<HabitDefinition> habits;

  const _LoadedView({required this.habits});

  // ── Edit ─────────────────────────────────────────────────────────────────
  // Navigate to HabitFormPage in edit mode (passing the habit). ManageHabitsBloc
  // is globally provided in DI so no explicit BlocProvider.value wrapping is needed.

  void _onEdit(BuildContext context, HabitDefinition habit) {
    AppRoute.editHabit.push(context, extra: habit);
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  // Show a confirmation dialog before dispatching the delete event.

  Future<void> _onDelete(BuildContext context, HabitDefinition habit) async {
    final confirmed = await AppDialog.show(
      context,
      icon: Icons.delete_outline_rounded,
      iconColor: red,
      title: 'Delete habit?',
      subtitle:
          '"${habit.title}" will be removed along with its progress. This cannot be undone.',
      confirmText: 'Delete',
      confirmColor: red,
    );

    if (confirmed != true || !context.mounted) return;

    // Delete via the repository directly so we can sequence the refreshes
    // *after* the write completes (avoids racing the cached fetches below).
    try {
      await context.read<HomeRepository>().deleteHabit(habit.id);
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.error(context, 'Could not delete habit. Please try again.');
      return; // Tile stays visible; the user can try again.
    }

    if (!context.mounted) return;

    // Refresh manage + home + insights so the deleted habit disappears
    // from the calendar, daily card, and weekly progress immediately.
    context.read<ManageHabitsBloc>().add(ManageHabitsStarted());
    context.read<HomeBloc>().add(HomeStarted());
    context.read<InsightsBloc>().add(InsightsRefreshRequested());

    // Re-sync so the deleted habit no longer fires reminders.
    context.read<NotificationBloc>().add(const HabitNotificationsSynced());

    AppSnackBar.success(context, 'Habit deleted successfully!');
  }

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) return const EmptyHabitView();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: PrimaryButton(
              height: 35,
              text: "Add Habit",
              isMainAxisSizeMin: true,
              onPressed: () {
                openAddHabitGated(context);
              },
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return ManageHabitTileWidget(
                habit: habit,
                onEdit: () => _onEdit(context, habit),
                onDelete: () => _onDelete(context, habit),
              );
            },
          ),
        ),
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
