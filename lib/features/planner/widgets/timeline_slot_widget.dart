import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/planner/models/planner_task.dart';
import 'package:purepath/features/planner/widgets/planner_hour_label.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Timeline slot
//
// One hourly row of the planner timeline: a time label + an add button on the
// left, and the tasks scheduled in that hour stacked on the right. Pure UI —
// all interaction is delegated up through callbacks.
// ─────────────────────────────────────────────────────────────────────────────

class TimelineSlot extends StatelessWidget {
  const TimelineSlot({
    super.key,
    required this.hour,
    required this.tasks,
    required this.onAdd,
    required this.onTaskTap,
    required this.onTaskToggle,
  });

  /// The slot this row represents (0 = 12 AM … 23 = 11 PM).
  final int hour;

  /// Tasks scheduled in this hour (already filtered by the page).
  final List<PlannerTask> tasks;

  final VoidCallback onAdd;
  final void Function(PlannerTask task) onTaskTap;
  final void Function(PlannerTask task) onTaskToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Time label ──────────────────────────────────────────────────
          SizedBox(
            width: 62,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                plannerHourLabel(hour),
                style: AppTextStyles.medium.copyWith(
                  fontSize: 13,
                  color: kLightGreyColor,
                ),
              ),
            ),
          ),
          Space.horizontal(10),

          // ── Add button ──────────────────────────────────────────────────
          _AddButton(onTap: onAdd),
          Space.horizontal(12),

          // ── Tasks for this hour ─────────────────────────────────────────
          Expanded(
            child: tasks.isEmpty
                // Keeps the row height stable when a slot is empty so the
                // add buttons line up down the whole timeline.
                ? const SizedBox(height: 40)
                : Column(
                    children: [
                      for (final task in tasks) ...[
                        _TaskCard(
                          task: task,
                          onTap: () => onTaskTap(task),
                          onToggle: () => onTaskToggle(task),
                        ),
                        if (task != tasks.last) Space.vertical(8),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add button — the "+" circle that opens the add-task sheet for this hour.
// ─────────────────────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: kContainerColor,
          shape: BoxShape.circle,
          border: Border.all(color: kLightGreyColor.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.add_rounded, size: 20, color: kLightGreyColor),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task card — one scheduled task with a check-off toggle. Tapping the card
// opens the edit sheet; tapping the circle toggles done.
// ─────────────────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  final PlannerTask task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final done = task.done;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kContainerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: done
                ? kPrimaryGreenColor.withValues(alpha: 0.5)
                : kLightGreyColor.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Check toggle ────────────────────────────────────────────
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: done ? kPrimaryGreenColor : kTransparentColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? kPrimaryGreenColor : kLightGreyColor,
                    width: 1.5,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, size: 14, color: kBlackColor)
                    : null,
              ),
            ),
            Space.horizontal(10),

            // ── Title + note ────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: done ? kLightGreyColor : kWhiteColor,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: kLightGreyColor,
                    ),
                  ),
                  if (task.note.isNotEmpty) ...[
                    Space.vertical(2),
                    Text(
                      task.note,
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 12,
                        color: kLightGreyColor,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: kLightGreyColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
