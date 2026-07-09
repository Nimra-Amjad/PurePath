import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';

/// One benefit line on the paywall: lime icon, bold title, grey detail.
class PaywallFeatureRow extends StatelessWidget {
  const PaywallFeatureRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kPrimaryGreenColor, size: 22),
        const Space.horizontal(14),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: AppTextStyles.bold.copyWith(
                    color: kWhiteColor,
                    fontSize: 15,
                  ),
                ),
                TextSpan(
                  text: ' — $detail',
                  style: AppTextStyles.normal.copyWith(
                    color: kLightGreyColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
