import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';

/// Shown on the home screen when the user *has* habits but none are scheduled
/// for the selected day. When they have no habits at all, [EmptyHabitView]
/// (with its "create your first habit" call-to-action) is shown instead.
class NoHabitForDayView extends StatelessWidget {
  const NoHabitForDayView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 54,
              color: textSecondary,
            ),
            Space.vertical(16),
            Text(
              'No habit for this day',
              style: AppTextStyles.bold.copyWith(
                fontSize: 18,
                color: kWhiteColor,
              ),
            ),
            Space.vertical(8),
            Text(
              "You don't have any habits set up\nfor this day.",
              style: AppTextStyles.normal.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
