import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';

class FeatureDetailWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const FeatureDetailWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kLightPurpleColor.withOpacityValue(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kMutedPurple, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: kLightBackground,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(8),
            child: Icon(icon, color: kDarkTealColor, size: 20),
          ),
          Space.horizontal(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bold.copyWith(fontSize: 18)),
                Text(
                  description,
                  style: AppTextStyles.normal.copyWith(
                    fontSize: 14,
                    color: kBlackColor.withOpacityValue(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
