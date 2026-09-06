import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/widgets/rounded_back_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/explore/data/habit_goals_data.dart';
import 'package:purepath/features/explore/models/habit_goal.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Explore Habits ("Habit ideas")
//
// A 2-column grid of goals (e.g. "Lose weight", "Sleep better"). Tapping a
// goal opens [GoalHabitsPage] ("More habits") with the concrete, curated
// habits that support it.
// ─────────────────────────────────────────────────────────────────────────────

class ExploreHabitsPage extends StatelessWidget {
  const ExploreHabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fixed header: back button + title/subtitle ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RoundedBackButton(onTap: () => context.pop()),
                  Space.horizontal(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Habit ideas',
                          style: AppTextStyles.bold.copyWith(
                            fontSize: 22,
                            color: kWhiteColor,
                          ),
                        ),
                        Space.vertical(4),
                        Text(
                          "Choose a goal. We'll suggest the habits for it.",
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
            ),
            Space.vertical(20),

            // ── Scrollable goal grid ─────────────────────────────────────
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                itemCount: kHabitGoals.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 172,
                ),
                itemBuilder: (context, i) => _GoalCard(goal: kHabitGoals[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Goal card — icon badge, title, subtitle, and habit count.
// ─────────────────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final HabitGoal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppRoute.goalHabits.push(context, extra: goal),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kContainerColor, kContainerColorContrast],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kWhiteColor.withOpacityValue(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
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
                    color: goal.color.withOpacityValue(0.22),
                    blurRadius: 16,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Icon(goal.icon, color: goal.color, size: 22),
            ),
            Space.vertical(14),
            Text(
              goal.title,
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 16,
                color: kWhiteColor,
              ),
            ),
            Space.vertical(4),
            Text(
              goal.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.normal.copyWith(
                fontSize: 12.5,
                color: kLightGreyColor,
                height: 1.3,
              ),
            ),
            const Spacer(),
            Text(
              '${goal.habits.length} HABITS',
              style: AppTextStyles.medium.copyWith(
                fontSize: 10.5,
                color: kLightGreyColor.withOpacityValue(0.7),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
