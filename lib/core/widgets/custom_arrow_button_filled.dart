import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/utils/utils.dart';

class CustomArrowButtonFilled extends StatelessWidget {
  final String svgAsset;
  final VoidCallback onTap;
  final bool isDisabled;
  const CustomArrowButtonFilled({
    super.key,
    required this.svgAsset,
    required this.onTap,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: isDisabled ? null : onTap,
      padding: EdgeInsets.zero,
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1.0,
        child: SvgPicture.asset(
          svgAsset,
          width: 20,
          height: 20,
          colorFilter: colorFilter(color: kWhiteColor),
        ),
      ),
    );
  }
}
