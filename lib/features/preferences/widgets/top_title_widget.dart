import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/widgets/space.dart';

class TopTitleWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  const TopTitleWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.bold.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        Space.vertical(8),
        Text(
          subtitle,
          style: AppTextStyles.normal.copyWith(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
