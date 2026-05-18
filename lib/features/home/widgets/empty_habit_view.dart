import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';

class EmptyHabitView extends StatelessWidget {
  const EmptyHabitView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🌱',
              style: AppTextStyles.bold.copyWith(
                fontSize: 50,
                color: kWhiteColor,
              ),
            ),
            Space.vertical(16),
            Text(
              'No habits yet',
              style: AppTextStyles.bold.copyWith(
                fontSize: 18,
                color: kWhiteColor,
              ),
            ),
            Space.vertical(8),
            Text(
              'Tap the + button on the home screen\nto create your first habit.',
              style: AppTextStyles.normal.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
            Space.vertical(12),
            PrimaryButton(
              text: "Add Habit",
              isMainAxisSizeMin: true,
              onPressed: () {
                AppRoute.addHabit.push(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
