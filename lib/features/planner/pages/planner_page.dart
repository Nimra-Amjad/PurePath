import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/widgets/app_dialog.dart';
import 'package:purepath/core/widgets/custom_error_view.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/widgets/horizontal_calendar_widget.dart';
import 'package:purepath/features/paywall/bloc/subscription_bloc.dart';
import 'package:purepath/features/planner/bloc/planner_bloc.dart';
import 'package:purepath/features/planner/models/planner_task.dart';
import 'package:purepath/features/planner/widgets/planner_task_sheet.dart';
import 'package:purepath/features/planner/widgets/timeline_slot_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Planner page
//
// A daily schedule. A weekly calendar on top (tap any day — past or future),
// and a 12 AM → 11 PM timeline below. Each hour has a "+" button that opens a
// sheet to schedule a task in that slot. Tasks render under their hour and can
// be checked off, edited, or deleted.
//
// Reads from the global [PlannerBloc] (registered in DI) and dispatches
// [PlannerStarted] in initState so today's plan is fetched on mount.
// ─────────────────────────────────────────────────────────────────────────────

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  /// 0 = 12 AM … 23 = 11 PM.
  static const _hours = 24;

  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    context.read<PlannerBloc>().add(PlannerStarted());
  }

  String _dateLabel(DateTime date) {
    final weekday = _weekdayNames[date.weekday - 1];
    final month = _monthNames[date.month - 1];
    return '$weekday, $month ${date.day}';
  }

  // ── Task actions ────────────────────────────────────────────────────────────

  void _onAdd(BuildContext context, int hour) {
    // Scheduling tasks is a Pro feature — free users hit the paywall first.
    if (!context.read<SubscriptionBloc>().state.isPro) {
      AppRoute.paywall.push(context);
      return;
    }

    final bloc = context.read<PlannerBloc>();
    final date = bloc.state.selectedDate;
    PlannerTaskSheet.showAdd(
      context,
      hour: hour,
      onSubmit: (title, note) => bloc.add(
        PlannerTaskAdded(date: date, hour: hour, title: title, note: note),
      ),
    );
  }

  void _onTaskTap(BuildContext context, PlannerTask task) {
    final bloc = context.read<PlannerBloc>();
    PlannerTaskSheet.showEdit(
      context,
      task: task,
      onSubmit: (title, note) => bloc.add(
        PlannerTaskUpdated(task.copyWith(title: title, note: note)),
      ),
      onDelete: () => _confirmDelete(context, task),
    );
  }

  Future<void> _confirmDelete(BuildContext context, PlannerTask task) async {
    final bloc = context.read<PlannerBloc>();
    final confirmed = await AppDialog.show(
      context,
      icon: Icons.delete_outline_rounded,
      iconColor: kRedColor,
      title: 'Delete task?',
      subtitle: 'This removes "${task.title}" from your plan.',
      confirmText: 'Delete',
      confirmColor: kRedColor,
    );
    if (confirmed == true) bloc.add(PlannerTaskDeleted(task.id));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlannerBloc, PlannerState>(
      builder: (context, state) {
        // A collapsing grey header: the title block scrolls away, and the
        // calendar pins to the top (staying put through any add/toggle/delete
        // operation) — it only drops back down when the user scrolls to the top.
        return CustomScrollView(
          slivers: [
            // ── Title block (grey, scrolls away) ─────────────────────────
            SliverToBoxAdapter(
              child: ColoredBox(
                color: kScaffoldColor,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Planner',
                        style: AppTextStyles.bold.copyWith(
                          fontSize: 24,
                          color: kWhiteColor,
                        ),
                      ),
                      Space.vertical(4),
                      Text(
                        _dateLabel(state.selectedDate),
                        style: AppTextStyles.normal.copyWith(
                          fontSize: 14,
                          color: kLightGreyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Calendar (grey, pins to the top on scroll) ───────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedCalendarHeader(
                // Grey layer peeking through only at the bottom → a rounded
                // grey bottom edge with no top/side lines (a bottom-only border
                // can't otherwise carry a corner radius in Flutter).
                child: Container(
                  decoration: BoxDecoration(
                    color: kLightGreyColor.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: kScaffoldColor,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: TrainingCalendar(
                      selectedDate: state.selectedDate,
                      visibleWeekStart: state.visibleWeekStart,
                      allowFuture: true,
                      onDateSelected: (date) => context
                          .read<PlannerBloc>()
                          .add(PlannerDateSelected(date)),
                      onWeekChanged: (weekStart) => context
                          .read<PlannerBloc>()
                          .add(PlannerWeekChanged(weekStart)),
                    ),
                  ),
                ),
              ),
            ),

            // ── Timeline ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: _buildTimeline(context, state),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeline(BuildContext context, PlannerState state) {
    if (state.status == PlannerStatus.error) {
      return CustomErrorView(
        message: state.errorMessage ?? 'Something went wrong',
        onRetry: () => context.read<PlannerBloc>().add(
          PlannerDateSelected(state.selectedDate),
        ),
      );
    }

    // Group the selected day's tasks by hour so each slot renders its own.
    final tasksByHour = <int, List<PlannerTask>>{};
    for (final task in state.selectedTasks) {
      tasksByHour.putIfAbsent(task.hour, () => []).add(task);
    }

    return Column(
      children: [
        for (int hour = 0; hour < _hours; hour++)
          TimelineSlot(
            hour: hour,
            tasks: tasksByHour[hour] ?? const [],
            onAdd: () => _onAdd(context, hour),
            onTaskTap: (task) => _onTaskTap(context, task),
            onTaskToggle: (task) =>
                context.read<PlannerBloc>().add(PlannerTaskToggled(task.id)),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pinned calendar header
//
// A fixed-height sliver header (min == max extent, so it never resizes) that
// pins the week calendar to the top of the scroll view. The calendar has a
// fixed intrinsic height; [_extent] is set a little larger so minor font
// rounding can never overflow — the slack is absorbed as grey space below it.
// ─────────────────────────────────────────────────────────────────────────────

class _PinnedCalendarHeader extends SliverPersistentHeaderDelegate {
  const _PinnedCalendarHeader({required this.child});

  final Widget child;

  /// Calendar card (~146) + the header's 4/12 vertical padding, plus a small
  /// safety margin so the child can never exceed the box.
  static const double _extent = 168;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_PinnedCalendarHeader oldDelegate) =>
      child != oldDelegate.child;
}
