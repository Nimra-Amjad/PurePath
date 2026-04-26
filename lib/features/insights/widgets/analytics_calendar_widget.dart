import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';

class AnalyticsCalendarWidget extends StatelessWidget {
  const AnalyticsCalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: kLightGreyColor,
          child: SvgPicture.asset(
            Assets.svgArrowBackIcon,
            width: 20,
            height: 20,
          ),
        ),
        Space.horizontal(6),
        Text("April 2026", style: AppTextStyles.normal.copyWith(fontSize: 16)),
        Space.horizontal(6),
        CircleAvatar(
          radius: 16,
          backgroundColor: kLightGreyColor,
          child: SvgPicture.asset(
            Assets.svgArrowForwardIcon,
            width: 20,
            height: 20,
          ),
        ),
      ],
    );
  }
}
