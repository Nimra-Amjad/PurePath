import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/bloc/home_bloc.dart';
import 'package:purepath/features/home/bloc/manage_habits_bloc.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/home/pages/edit_habit_page.dart';
import 'package:purepath/features/home/repositories/home_repository.dart';
import 'package:purepath/features/home/widgets/manage_habit_tile_widget.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/notifications/bloc/notification_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Manage habits page
//
// Reads from the global [ManageHabitsBloc] (registered in DI) and dispatches
// [ManageHabitsStarted] in initState so the latest list is fetched every
// time the page is opened.
// ─────────────────────────────────────────────────────────────────────────────

class ManageHabitsPage extends StatefulWidget {
  const ManageHabitsPage({super.key});

  @override
  State<ManageHabitsPage> createState() => _ManageHabitsPageState();
}

class _ManageHabitsPageState extends State<ManageHabitsPage> {
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
      backgroundColor: kWhiteColor,
      appBar: _buildAppBar(context),
      body: BlocBuilder<ManageHabitsBloc, ManageHabitsState>(
        builder: (context, state) {
          return switch (state.status) {
            ManageHabitsStatus.loading => const _LoadingView(),
            ManageHabitsStatus.error => _ErrorView(
              message: state.errorMessage ?? 'Something went wrong.',
            ),
            ManageHabitsStatus.loaded => _LoadedView(habits: state.habits),
          };
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: kWhiteColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: kBlackColor,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'My Habits',
        style: AppTextStyles.bold.copyWith(fontSize: 20),
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
  // Navigate to EditHabitPage while sharing the current ManageHabitsBloc so
  // the edit form can dispatch ManageHabitUpdateRequested directly.

  void _onEdit(BuildContext context, HabitDefinition habit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ManageHabitsBloc>(),
          child: EditHabitPage(habit: habit),
        ),
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  // Show a confirmation dialog before dispatching the delete event.

  Future<void> _onDelete(BuildContext context, HabitDefinition habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(habitTitle: habit.title),
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
    if (habits.isEmpty) return const _EmptyView();

    return ListView.builder(
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty view
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏃', style: TextStyle(fontSize: 56)),
            Space.vertical(16),
            Text(
              'No habits yet',
              style: AppTextStyles.bold.copyWith(fontSize: 18),
            ),
            Space.vertical(8),
            Text(
              'Tap the + button on the home screen\nto create your first habit.',
              style: AppTextStyles.normal.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete confirmation dialog
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  final String habitTitle;

  const _DeleteConfirmDialog({required this.habitTitle});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kWhiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Delete Habit',
        style: AppTextStyles.bold.copyWith(fontSize: 18),
      ),
      content: Text(
        'Are you sure you want to delete "$habitTitle"?\nThis cannot be undone.',
        style: AppTextStyles.normal.copyWith(color: textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: AppTextStyles.medium.copyWith(color: textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: red,
            foregroundColor: kWhiteColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Delete',
            style: AppTextStyles.semiBold.copyWith(color: kWhiteColor),
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
      child: CircularProgressIndicator(color: purple),
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
                  context.read<ManageHabitsBloc>().add(ManageHabitsStarted()),
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
