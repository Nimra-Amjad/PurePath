import 'package:flutter/material.dart';
import 'package:purepath/core/constants/color_constants.dart';

class CustomHorizontalDivider extends StatelessWidget {
  final Color? color;
  final double? width;
  const CustomHorizontalDivider({super.key, this.color, this.width});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: color ?? kGreyColor,
      thickness: width ?? 0.5,
      height: 0,
    );
  }
}
