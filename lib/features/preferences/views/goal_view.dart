import 'package:flutter/material.dart';
import 'package:purepath/core/widgets/custom_single_selection_widget.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/preferences/widgets/top_title_widget.dart';

class GoalView extends StatefulWidget {
  const GoalView({super.key, this.onGoalChanged});

  /// Called whenever the user picks a different goal.
  /// [PreferencesPage] listens to this to know what to save.
  final ValueChanged<String>? onGoalChanged;

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
  void initState() {
    super.initState();
    // Report the default selection immediately so PreferencesPage has a value
    // even if the user never taps anything.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onGoalChanged?.call(selectedGoal!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopTitleWidget(
          title: "What's your primary focus right now?",
          subtitle: "This will help us tailor your experience and goals.",
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
                setState(() => selectedGoal = value);
                widget.onGoalChanged?.call(value!);
              },
            ),
          ),
        ),
      ],
    );
  }
}
