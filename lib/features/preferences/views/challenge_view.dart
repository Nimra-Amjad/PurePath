import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/widgets/custom_single_selection_widget.dart';
import 'package:purepath/core/widgets/space.dart';

class ChallengeView extends StatefulWidget {
  const ChallengeView({super.key});

  @override
  State<ChallengeView> createState() => _ChallengeViewState();
}

class _ChallengeViewState extends State<ChallengeView> {
  static const challengeOptions = <String>[
    'I forget to do them',
    'I lose motivation quickly',
    'I take on too much at once',
    'I don\'t have a clear plan',
  ];

  String? selectedChallenge = challengeOptions.first;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "What's been your biggest challenge with habits?",
          style: AppTextStyles.bold.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        Space.vertical(8),
        Text(
          "This will help us tailor your experience and challenges.",
          style: AppTextStyles.normal.copyWith(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        Space.vertical(16),
        ...challengeOptions.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CustomSingleSelectionWidget<String>(
              value: option,
              selectedValue: selectedChallenge,
              title: option,
              onChanged: (value) {
                setState(() {
                  selectedChallenge = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
