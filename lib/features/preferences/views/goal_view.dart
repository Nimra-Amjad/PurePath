import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/widgets/custom_single_selection_widget.dart';
import 'package:purepath/core/widgets/space.dart';

class GoalView extends StatefulWidget {
  const GoalView({super.key});

  @override
  State<GoalView> createState() => _GoalViewState();
}

class _GoalViewState extends State<GoalView> {
  static const goalOptions = <String>[
    '🏃‍♂️ Fitness & Health',
    '🧠 Mental Clarity',
    '📚 Learning & Skills',
    '🧹 Organization',
  ];

  String? selectedGoal = goalOptions.first;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "What's your primary focus right now?",
          style: AppTextStyles.bold.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        Space.vertical(8),
        Text(
          "This will help us tailor your experience and goals.",
          style: AppTextStyles.normal.copyWith(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        Space.vertical(16),
        ...goalOptions.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CustomSingleSelectionWidget<String>(
              value: option,
              selectedValue: selectedGoal,
              title: option,
              onChanged: (value) {
                setState(() {
                  selectedGoal = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
