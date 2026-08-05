import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/custom_back_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/insights/widgets/habit_collection_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit collection page
//
// The full "View All" screen reached from the collection preview on the
// insights tab. Renders one dot-grid card per habit, reading straight from the
// shared global [InsightsBloc] (already loaded by the insights tab).
// ─────────────────────────────────────────────────────────────────────────────

class HabitCollectionPage extends StatelessWidget {
  const HabitCollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: AppBar(
        backgroundColor: kScaffoldColor,
        surfaceTintColor: kScaffoldColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: CustomBackButton(onTap: () => context.pop()),
        ),
        title: Text(
          'Habit Collection',
          style: AppTextStyles.bold.copyWith(fontSize: 18, color: kWhiteColor),
        ),
      ),
      body: BlocBuilder<InsightsBloc, InsightsState>(
        builder: (context, state) {
          final habits = state.habits;

          if (habits.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No habits yet.\nCreate a habit to start building your collection.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.normal.copyWith(
                    fontSize: 14,
                    color: kSecondaryGreyColor,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              // Scrolling list of habit grids.
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final habit in habits) ...[
                        HabitCollectionCard(
                          habit: habit,
                          history: state.completionHistory,
                          days: InsightsBloc.historyDays,
                        ),
                        Space.vertical(16),
                      ],
                    ],
                  ),
                ),
              ),

              // Legend pinned to the bottom of the screen.
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: const HabitCollectionLegend(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
