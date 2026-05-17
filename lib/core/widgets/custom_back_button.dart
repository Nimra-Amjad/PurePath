import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/utils/utils.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const CustomBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 35,
      height: 35,
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        child: SvgPicture.asset(
          Assets.svgArrowBackIcon,
          width: 20,
          height: 20,
          colorFilter: colorFilter(color: kWhiteColor),
        ),
      ),
    );
  }
}
