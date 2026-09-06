import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/widgets/app_dialog.dart';
import 'package:purepath/core/widgets/rounded_back_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/core/repositories/home_repository.dart';
import 'package:purepath/features/explore/models/habit_goal.dart';
import 'package:purepath/features/explore/widgets/configure_predefined_habit_sheet.dart';
import 'package:purepath/features/home/bloc/home_bloc.dart';
import 'package:purepath/features/home/bloc/manage_habits_bloc.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/notifications/bloc/notification_bloc.dart';
import 'package:purepath/features/paywall/utils/habit_limit_gate.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Goal habits page ("More habits")
//
// The suggested-habit list for a single [HabitGoal]. Tapping a row's + opens
// the configure sheet (schedule + reminder); confirming persists it through
// [HomeRepository] — the same path the Add/Edit Habit screens use — and
// refreshes every bloc that displays habits.
//
// The set of already-added suggestions is loaded once on entry (and kept in
// sync after each add/delete) so a row's +/− state survives re-opening the
// page.
// ─────────────────────────────────────────────────────────────────────────────

class GoalHabitsPage extends StatefulWidget {
  final HabitGoal goal;

  const GoalHabitsPage({super.key, required this.goal});

  @override
  State<GoalHabitsPage> createState() => _GoalHabitsPageState();
}

class _GoalHabitsPageState extends State<GoalHabitsPage> {
  /// Maps a suggestion's title → the id of the matching habit the user owns.
  /// Presence of a key means "already added"; the value is needed to delete it.
  final Map<String, String> _addedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reloadAddedIds();
  }

  Future<void> _reloadAddedIds() async {
    try {
      final habits = await context.read<HomeRepository>().getAllHabits();
      if (!mounted) return;
      setState(() {
        _addedIds
          ..clear()
          ..addEntries(habits.map((h) => MapEntry(h.title, h.id)));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _refreshDependentBlocs() {
    context.read<HomeBloc>().add(HomeStarted());
    context.read<ManageHabitsBloc>().add(ManageHabitsStarted());
    context.read<InsightsBloc>().add(InsightsRefreshRequested());
    context.read<NotificationBloc>().add(const HabitNotificationsSynced());
  }

  Future<void> _persistHabit(HabitDefinition habit) async {
    // Free plan is capped — opens the paywall instead once the limit is hit.
    if (!await canAddHabit(context)) return;
    if (!mounted) return;
    try {
      await context.read<HomeRepository>().addHabit(habit);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Could not add habit. Please try again.');
      return;
    }

    if (!mounted) return;
    _refreshDependentBlocs();
    await _reloadAddedIds();
    if (!mounted) return;
    AppSnackBar.success(context, 'Added to your habits!');
  }

  Future<void> _deleteHabit(String id) async {
    try {
      await context.read<HomeRepository>().deleteHabit(id);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Could not delete habit. Please try again.');
      return;
    }

    if (!mounted) return;
    _refreshDependentBlocs();
    await _reloadAddedIds();
    if (!mounted) return;
    AppSnackBar.success(context, 'Removed from your habits.');
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;

    return Scaffold(
      backgroundColor: kScaffoldColor,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: kPrimaryGreenColor),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // ── Top bar ──────────────────────────────────────────────
                  Row(
                    children: [
                      RoundedBackButton(onTap: () => context.pop()),
                      Space.horizontal(14),
                      Text(
                        'More habits',
                        style: AppTextStyles.semiBold.copyWith(
                          fontSize: 18,
                          color: kWhiteColor,
                        ),
                      ),
                    ],
                  ),
                  Space.vertical(20),

                  // ── Goal header card ─────────────────────────────────────
                  _GoalHeaderCard(goal: goal),
                  Space.vertical(20),

                  // ── Suggested habits ─────────────────────────────────────
                  for (var i = 0; i < goal.habits.length; i++) ...[
                    _GoalHabitRow(
                      idea: goal.habits[i],
                      color: goal.color,
                      isAdded: _addedIds.containsKey(goal.habits[i].title),
                      onAdd: _persistHabit,
                      onDelete: () async {
                        final id = _addedIds[goal.habits[i].title];
                        if (id != null) await _deleteHabit(id);
                      },
                    ),
                    if (i != goal.habits.length - 1) Space.vertical(12),
                  ],
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Goal header card — icon badge + title + subtitle, tinted with goal.color.
// ─────────────────────────────────────────────────────────────────────────────

class _GoalHeaderCard extends StatelessWidget {
  final HabitGoal goal;
  const _GoalHeaderCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kContainerColor, kContainerColorContrast],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: goal.color.withOpacityValue(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  goal.color.withOpacityValue(0.28),
                  goal.color.withOpacityValue(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: goal.color.withOpacityValue(0.25),
                  blurRadius: 18,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Icon(goal.icon, color: goal.color, size: 26),
          ),
          Space.horizontal(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: AppTextStyles.bold.copyWith(
                    fontSize: 19,
                    color: kWhiteColor,
                  ),
                ),
                Space.vertical(2),
                Text(
                  goal.subtitle,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Goal habit row — icon badge + title + tap-to-add (+) / tap-to-remove (−).
// ─────────────────────────────────────────────────────────────────────────────

class _GoalHabitRow extends StatefulWidget {
  final HabitIdea idea;
  final Color color;
  final bool isAdded;
  final Future<void> Function(HabitDefinition habit) onAdd;
  final Future<void> Function() onDelete;

  const _GoalHabitRow({
    required this.idea,
    required this.color,
    required this.isAdded,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  State<_GoalHabitRow> createState() => _GoalHabitRowState();
}

class _GoalHabitRowState extends State<_GoalHabitRow> {
  bool _busy = false;

  Future<void> _onAddTap() async {
    if (_busy) return;

    final habit = await ConfigurePredefinedHabitSheet.show(
      context,
      title: widget.idea.title,
    );
    if (habit == null || !mounted) return;

    setState(() => _busy = true);
    await widget.onAdd(habit);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _onRemoveTap() async {
    if (_busy) return;

    final confirmed = await AppDialog.show(
      context,
      icon: Icons.delete_outline_rounded,
      iconColor: kRedColor,
      title: 'Delete this habit?',
      subtitle:
          'Are you sure you want to delete this habit? It will be removed '
          'from your habits.',
      confirmText: 'Delete',
      confirmColor: kRedColor,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    await widget.onDelete();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isAdded || _busy ? null : _onAddTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kContainerColor, kContainerColorContrast],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color.withOpacityValue(0.26),
                    widget.color.withOpacityValue(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacityValue(0.2),
                    blurRadius: 12,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Icon(widget.idea.icon, color: widget.color, size: 20),
            ),
            Space.horizontal(12),
            Expanded(
              child: Text(
                widget.idea.title,
                style: AppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kWhiteColor,
                ),
              ),
            ),
            Space.horizontal(8),
            _buildTrailing(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailing() {
    if (_busy) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: kPrimaryGreenColor,
          strokeWidth: 2,
        ),
      );
    }

    final added = widget.isAdded;
    return GestureDetector(
      onTap: added ? _onRemoveTap : _onAddTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kContainerColorContrast,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: added
                ? kRedColor.withOpacityValue(0.4)
                : kWhiteColor.withOpacityValue(0.12),
          ),
        ),
        child: Icon(
          added ? Icons.remove_rounded : Icons.add_rounded,
          color: added ? kRedColor : kLightGreyColor,
          size: 18,
        ),
      ),
    );
  }
}
