import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/paywall/models/paywall_plan.dart';

/// Selectable pricing card. The selected card gets a lime border and a
/// lime-tinted fill; the plan's badge (e.g. "SAVE 50%") floats over the
/// top edge.
class PaywallPlanCard extends StatelessWidget {
  const PaywallPlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PaywallPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: selected
                  ? kPrimaryGreenColor.withOpacityValue(0.08)
                  : kContainerColorContrast,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? kPrimaryGreenColor
                    : kWhiteColor.withOpacityValue(0.08),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  plan.title,
                  style: AppTextStyles.medium.copyWith(
                    color: selected ? kWhiteColor : kLightGreyColor,
                    fontSize: 15,
                  ),
                ),
                const Space.vertical(4),
                Text(
                  plan.price,
                  style: AppTextStyles.bold.copyWith(
                    color: kWhiteColor,
                    fontSize: 24,
                    height: 1.2,
                  ),
                ),
                const Space.vertical(4),
                Text(
                  plan.caption,
                  style: AppTextStyles.normal.copyWith(
                    color: kSecondaryGreyColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (plan.badge != null)
            Positioned(
              top: -11,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: kPrimaryGreenColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  plan.badge!,
                  style: AppTextStyles.bold.copyWith(
                    color: kBlackColor,
                    fontSize: 11,
                    height: 1.4,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
