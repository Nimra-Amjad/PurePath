import 'package:flutter/material.dart';
import 'package:purepath/core/constants/color_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sheet handle bar
//
// The small grey pill shown at the top of every bottom sheet so the user knows
// they can drag it down to dismiss.
// ─────────────────────────────────────────────────────────────────────────────

class SheetHandleBar extends StatelessWidget {
  const SheetHandleBar({super.key, this.topPadding = 10});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(top: topPadding),
        width: 92,
        height: 5,
        decoration: BoxDecoration(
          color: kLightGreyColor,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
