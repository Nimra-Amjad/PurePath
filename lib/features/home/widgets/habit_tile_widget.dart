import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/habit_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit tile widget
//
// Displays a single habit row: icon, title, subtitle, and a checkmark badge.
// Tapping the tile fires [onTap] — the parent dispatches [HabitToggled] to
// the bloc, which toggles completion and updates the calendar arc + progress
// card automatically. This widget stays free of all business logic.
// ─────────────────────────────────────────────────────────────────────────────

class HabitTileWidget extends StatelessWidget {
  final HabitModel habit;

  /// Called when the user taps the tile.
  /// Parent is responsible for dispatching [HabitToggled] to [HomeBloc].
  final VoidCallback onTap;

  const HabitTileWidget({
    super.key,
    required this.habit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = habit.category.color;
    final icon = habit.category.icon;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
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
            // Category icon
            CircleAvatar(
              backgroundColor: color.withOpacityValue(0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            Space.horizontal(12),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.title, style: AppTextStyles.bold),
                  Space.vertical(4),
                  Text(
                    habit.subtitle,
                    style: AppTextStyles.normal.copyWith(color: kDarkGreyColor),
                  ),
                ],
              ),
            ),
            Space.horizontal(12),

            // Checkmark badge — animates between grey (pending) and purple (done)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: habit.isCompleted ? purple : Colors.grey.shade200,
              ),
              child: habit.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
