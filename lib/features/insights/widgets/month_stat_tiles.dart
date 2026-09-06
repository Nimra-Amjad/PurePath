import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Month stat tiles
//
//   ┌──────────┐ ┌──────────┐ ┌──────────┐
//   │ 78%      │ │ 140      │ │ 1        │
//   │ MONTH MET│ │ DAYS DONE│ │ PERFECT  │
//   └──────────┘ └──────────┘ └──────────┘
//
// Three summary tiles for the visible month. The first shows the "% met" with a
// small superscript-style "%"; the others show a plain count.
// ─────────────────────────────────────────────────────────────────────────────

class MonthStatTiles extends StatelessWidget {
  final int metPercent;
  final int daysDone;
  final int perfect;

  const MonthStatTiles({
    super.key,
    required this.metPercent,
    required this.daysDone,
    required this.perfect,
  });

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight bounds the row's height so the stretched tiles share one
    // height — without it, stretch can't resolve inside the scroll view.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Tile(value: '$metPercent', suffix: '%', label: 'MONTH MET'),
          ),
          Space.horizontal(12),
          Expanded(child: _Tile(value: '$daysDone', label: 'DAYS DONE')),
          Space.horizontal(12),
          Expanded(child: _Tile(value: '$perfect', label: 'PERFECT')),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String value;
  final String? suffix;
  final String label;

  const _Tile({required this.value, this.suffix, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.bold.copyWith(
                  fontSize: 26,
                  height: 1.0,
                  color: kWhiteColor,
                ),
              ),
              if (suffix != null)
                Text(
                  suffix!,
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 13,
                    color: kLightGreyColor,
                  ),
                ),
            ],
          ),
          Space.vertical(8),
          Text(
            label,
            style: AppTextStyles.medium.copyWith(
              fontSize: 11,
              letterSpacing: 0.8,
              color: kLightGreyColor,
            ),
          ),
        ],
      ),
    );
  }
}
