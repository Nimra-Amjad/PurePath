import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "GOOD MORNING",
              style: AppTextStyles.normal.copyWith(color: kDarkGreyColor),
            ),
            Space.vertical(2),
            Text("Ahmad", style: AppTextStyles.bold.copyWith(fontSize: 20)),
          ],
        ),
        CircleAvatar(
          backgroundColor: kPrimaryColor.withOpacityValue(0.8),
          child: Text(
            "A",
            style: AppTextStyles.bold.copyWith(
              fontSize: 20,
              color: kWhiteColor,
            ),
          ),
        ),
      ],
    );
  }
}