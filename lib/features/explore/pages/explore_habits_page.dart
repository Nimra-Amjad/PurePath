import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/widgets/app_dialog.dart';
import 'package:purepath/core/widgets/custom_back_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/explore/data/habit_library_data.dart';
import 'package:purepath/features/explore/models/intensity_level.dart';
import 'package:purepath/features/explore/widgets/configure_predefined_habit_sheet.dart';
import 'package:purepath/features/home/bloc/home_bloc.dart';
import 'package:purepath/features/home/bloc/manage_habits_bloc.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/core/repositories/home_repository.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/notifications/bloc/notification_bloc.dart';
import 'package:purepath/features/paywall/utils/habit_limit_gate.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Explore Habits (Habit Library)
//
// A single flat catalog of suggested habits grouped by [IntensityLevel]
// (Beginner → Intermediate → Advanced). Habits no longer have categories, so
// there are no tabs — the user just scrolls the list.
//
// Each habit shows a + to add it to the user's habits and, once added, a −
// to remove it again (with a confirmation dialog). Both paths go through
// [HomeRepository] — the same path used by the Add/Edit Habit screens — and
// refresh the home, manage, insights and notification blocs so the change
// shows up everywhere at once.
//
// The set of already-added library habits is loaded once on entry (and kept in
// sync after each add/delete) so the +/− state is correct even after re-opening
// the screen.
// ─────────────────────────────────────────────────────────────────────────────

class ExploreHabitsPage extends StatefulWidget {
  const ExploreHabitsPage({super.key});

  @override
  State<ExploreHabitsPage> createState() => _ExploreHabitsPageState();
}

class _ExploreHabitsPageState extends State<ExploreHabitsPage> {
  /// Maps a library habit key → the id of the matching habit the user owns.
  /// Presence of a key means "already added"; the value is needed to delete it.
  final Map<String, String> _addedIds = {};
  bool _loading = true;

  /// Stable identity for a library habit — its title. Library titles are unique
  /// across the catalog, so this uniquely matches a user habit back to its row.
  static String keyFor(String title) => title;

  @override
  void initState() {
    super.initState();
    _reloadAddedIds();
  }

  /// Re-reads the user's habits and rebuilds [_addedIds] so every card reflects
  /// the current add/delete state.
  Future<void> _reloadAddedIds() async {
    try {
      final habits = await context.read<HomeRepository>().getAllHabits();
      if (!mounted) return;
      setState(() {
        _addedIds
          ..clear()
          ..addEntries(
            habits.map((h) => MapEntry(keyFor(h.title), h.id)),
          );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Refreshes every screen that displays habits — mirrors Add/Edit Habit.
  void _refreshDependentBlocs() {
    context.read<HomeBloc>().add(HomeStarted());
    context.read<ManageHabitsBloc>().add(ManageHabitsStarted());
    context.read<InsightsBloc>().add(InsightsRefreshRequested());
    context.read<NotificationBloc>().add(const HabitNotificationsSynced());
  }

  /// Persists a habit the user already configured in the sheet. The card owns
  /// the spinner around this call, so it only spins during the actual save.
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
    // addHabit doesn't return the generated id — re-fetch to resolve it so the
    // card knows what to delete if the user taps − later.
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
    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: AppBar(
        backgroundColor: kScaffoldColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: CustomBackButton(onTap: () => context.pop()),
        title: Text(
          'Habit Library',
          style: AppTextStyles.bold.copyWith(
            fontSize: 20,
            color: kWhiteColor,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimaryGreenColor),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                for (final level in IntensityLevel.values) ...[
                  _LevelHeader(level: level),
                  Space.vertical(12),
                  ...(kHabitLibrary[level] ?? const <String>[]).map(
                    (habit) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LibraryHabitCard(
                        title: habit,
                        isAdded: _addedIds.containsKey(keyFor(habit)),
                        onAdd: _persistHabit,
                        onDelete: () async {
                          final id = _addedIds[keyFor(habit)];
                          if (id != null) await _deleteHabit(id);
                        },
                      ),
                    ),
                  ),
                  Space.vertical(16),
                ],
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Intensity section header
// ─────────────────────────────────────────────────────────────────────────────

class _LevelHeader extends StatelessWidget {
  final IntensityLevel level;
  const _LevelHeader({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: level.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(level.icon, color: level.color, size: 18),
        ),
        Space.horizontal(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level.label,
                style: AppTextStyles.semiBold.copyWith(
                  fontSize: 15,
                  color: kWhiteColor,
                ),
              ),
              Text(
                level.description,
                style: AppTextStyles.normal.copyWith(
                  fontSize: 12,
                  color: kLightGreyColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Library habit card — title + tap-to-add (+) / tap-to-remove (−) control
// ─────────────────────────────────────────────────────────────────────────────

class _LibraryHabitCard extends StatefulWidget {
  final String title;

  /// Whether this habit already exists in the user's habits.
  final bool isAdded;

  /// Persists the configured habit. The card builds the [HabitDefinition] from
  /// the configure sheet and hands it off here.
  final Future<void> Function(HabitDefinition habit) onAdd;
  final Future<void> Function() onDelete;

  const _LibraryHabitCard({
    required this.title,
    required this.isAdded,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  State<_LibraryHabitCard> createState() => _LibraryHabitCardState();
}

class _LibraryHabitCardState extends State<_LibraryHabitCard> {
  bool _busy = false;

  Future<void> _onAddTap() async {
    if (_busy) return;

    // Open the configure sheet first — no spinner while the user is picking
    // options. The spinner only appears once they tap "Add Habit".
    final habit = await ConfigurePredefinedHabitSheet.show(
      context,
      title: widget.title,
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
      // Tapping anywhere on an un-added tile opens the configure sheet; an
      // already-added tile only responds to its − (remove) button.
      onTap: widget.isAdded || _busy ? null : _onAddTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kContainerColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: kSecondaryGreyColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: kHabitAccentColor.withValues(alpha: 0.2),
              child: const Text(
                kHabitEmoji,
                style: TextStyle(fontSize: 15),
              ),
            ),
            Space.horizontal(12),
            Expanded(
              child: Text(
                widget.title,
                style: AppTextStyles.medium.copyWith(
                  fontSize: 13,
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
        width: 22,
        height: 22,
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
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: added ? kRedColor : kPrimaryGreenColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          added ? Icons.remove_rounded : Icons.add_rounded,
          color: added ? kWhiteColor : kBlackColor,
          size: 18,
        ),
      ),
    );
  }
}
