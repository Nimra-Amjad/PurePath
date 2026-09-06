import 'package:flutter/material.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Rounded back button — small dark square with a chevron.
// ─────────────────────────────────────────────────────────────────────────────

class RoundedBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const RoundedBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kContainerColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: kWhiteColor.withOpacityValue(0.06)),
        ),
        child: const Icon(
          Icons.chevron_left_rounded,
          size: 22,
          color: kWhiteColor,
        ),
      ),
    );
  }
}
