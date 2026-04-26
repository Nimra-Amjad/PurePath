import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';

class BarChartWidget extends StatelessWidget {
  const BarChartWidget({super.key});

  final List<double> values = const [0.4, 0.7, 0.6, 0.9, 0.65, 0.5, 0.0];

  final List<String> days = const [
    "MON",
    "TUE",
    "WED",
    "THU",
    "FRI",
    "SAT",
    "SUN",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: kBlackColor.withOpacityValue(0.1), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          return BarItem(value: values[index], label: days[index]);
        }),
      ),
    );
  }
}

class BarItem extends StatelessWidget {
  final double value;
  final String label;

  const BarItem({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: 150,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Background bar
              Container(
                width: 40,
                decoration: BoxDecoration(
                  color: kLightGreyColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              // Foreground bar
              FractionallySizedBox(
                heightFactor: value,
                child: Container(
                  width: 40,
                  decoration: BoxDecoration(
                    color: kRedColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Space.vertical(8),
        Text(label, style: AppTextStyles.normal.copyWith(fontSize: 12)),
      ],
    );
  }
}
