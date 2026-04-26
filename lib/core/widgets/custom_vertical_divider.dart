import 'package:flutter/material.dart';
import 'package:purepath/core/constants/color_constants.dart';

class CustomVerticalDivider extends StatelessWidget {
  const CustomVerticalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: VerticalDivider(color: kGreyColor, thickness: 0.5, width: 10.0),
    );
  }
}
