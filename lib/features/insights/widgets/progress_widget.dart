import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';

class ProgressWidget extends StatelessWidget {
  final String title;
  final double progress;

  const ProgressWidget({
    super.key,
    required this.title,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kLightGreyColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // 📘 Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kGreenColor.withOpacityValue(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book, color: kGreenColor),
          ),
          Space.horizontal(12),

          // 📝 Title
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.medium.copyWith(fontSize: 16),
            ),
          ),

          // 📊 Progress bar
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: kGreenColor.withOpacityValue(0.2),
                valueColor: const AlwaysStoppedAnimation(kGreenColor),
              ),
            ),
          ),
          Space.horizontal(10),
          // 📈 Percentage
          Text("${(progress * 100).toInt()}%", style: AppTextStyles.medium),
        ],
      ),
    );
  }
}
