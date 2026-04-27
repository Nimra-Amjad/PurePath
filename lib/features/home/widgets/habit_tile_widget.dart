import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/habit_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit tile widget
//
// Displays one habit row: category emoji avatar, title, subtitle,
// and an animated checkmark badge.
//
// Tapping fires [onTap] → parent dispatches [HabitToggled] to [HomeBloc],
// which toggles completion and propagates the change to both the calendar
// arc and the daily progress card automatically.
//
// This widget is purely for display — no business logic lives here.
// ─────────────────────────────────────────────────────────────────────────────

class HabitTileWidget extends StatelessWidget {
  final HabitModel habit;

  /// Called when the tile is tapped.
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
    final emoji = habit.category.emoji;

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
            // Category emoji inside a tinted circle
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacityValue(0.15),
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
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

            // Checkmark badge — animates between grey (pending) and category color (done)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: habit.isCompleted ? color : Colors.grey.shade200,
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
