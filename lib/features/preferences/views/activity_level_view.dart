import 'package:flutter/material.dart';
import 'package:purepath/core/widgets/custom_single_selection_widget.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/preferences/widgets/top_title_widget.dart';

class ActivityLevelView extends StatefulWidget {
  const ActivityLevelView({super.key, this.onActivityLevelChanged});

  /// Called whenever the user picks a different activity level.
  /// [PreferencesPage] listens to this to know what to save.
  final ValueChanged<String>? onActivityLevelChanged;

  @override
  State<ActivityLevelView> createState() => _ActivityLevelViewState();
}

class _ActivityLevelViewState extends State<ActivityLevelView> {
  static const activityLevelOptions = <String>[
    '🌱 Beginner',
    '🚶 Intermediate',
    '🏆 Advanced',
  ];

  String? selectedActivityLevel = activityLevelOptions.first;

  @override
  void initState() {
    super.initState();
    // Report the default selection immediately so PreferencesPage has a value
    // even if the user never taps anything.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onActivityLevelChanged?.call(selectedActivityLevel!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopTitleWidget(
          title: "What kind of activities suit you best?",
          subtitle: "Pick the level that matches where you are right now.",
        ),
        Space.vertical(16),
        ...activityLevelOptions.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CustomSingleSelectionWidget<String>(
              value: option,
              selectedValue: selectedActivityLevel,
              title: option,
              onChanged: (value) {
                setState(() => selectedActivityLevel = value);
                widget.onActivityLevelChanged?.call(value!);
              },
            ),
          ),
        ),
      ],
    );
  }
}
