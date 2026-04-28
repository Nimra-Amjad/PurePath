import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/home/models/habit_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Manage habit tile widget
//
// Displays a single [HabitDefinition] row with Edit and Delete action buttons.
//
// Pure display — no business logic. All actions are surfaced via callbacks
// so the parent (ManageHabitsPage) can handle confirmation dialogs and BLoC
// dispatches.
// ─────────────────────────────────────────────────────────────────────────────

class ManageHabitTileWidget extends StatelessWidget {
  final HabitDefinition habit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ManageHabitTileWidget({
    super.key,
    required this.habit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = habit.category.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kBlackColor.withOpacityValue(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Category emoji avatar ───────────────────────────────────────
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacityValue(0.15),
            child: Text(
              habit.category.emoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Space.horizontal(12),

          // ── Title + meta ────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.title, style: AppTextStyles.semiBold),
                Space.vertical(3),
                Text(
                  habit.subtitle,
                  style: AppTextStyles.normal.copyWith(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                Space.vertical(4),
                // Frequency badge
                _FrequencyBadge(
                  label: habit.frequencyLabel,
                  color: color,
                ),
              ],
            ),
          ),

          // ── Action buttons ──────────────────────────────────────────────
          _IconActionButton(
            icon: Icons.edit_outlined,
            color: purple,
            tooltip: 'Edit',
            onTap: onEdit,
          ),
          Space.horizontal(4),
          _IconActionButton(
            icon: Icons.delete_outline_rounded,
            color: red,
            tooltip: 'Delete',
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Frequency badge — small pill showing "Daily" or "Weekly"
// ─────────────────────────────────────────────────────────────────────────────

class _FrequencyBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _FrequencyBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacityValue(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.medium.copyWith(fontSize: 11, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon action button — small tappable icon with background circle
// ─────────────────────────────────────────────────────────────────────────────

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacityValue(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
