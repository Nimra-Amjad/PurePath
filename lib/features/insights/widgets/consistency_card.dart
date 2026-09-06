import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Consistency card
//
//   ┌────────────────────────────────────────────────┐
//   │  CONSISTENCY                          ╭──────╮   │
//   │  76%                                  │  32  │   │
//   │  ↗ +12% vs last week                  │ OF 42│   │
//   │                                       ╰──────╯   │
//   └────────────────────────────────────────────────┘
//
// The big percentage is the week's overall consistency (completed habit-days ÷
// scheduled habit-days). The ring on the right shows the same ratio as
// "done OF scheduled". The trend chip is only shown when last week is loaded.
// ─────────────────────────────────────────────────────────────────────────────

class ConsistencyCard extends StatelessWidget {
  /// Consistency for the visible week (0.0 → 1.0).
  final double consistency;

  /// Completed habit-days this week (ring numerator).
  final int completed;

  /// Scheduled habit-days this week (ring denominator).
  final int scheduled;

  /// Change vs last week in whole percentage points, or null to hide the chip.
  final int? deltaPoints;

  const ConsistencyCard({
    super.key,
    required this.consistency,
    required this.completed,
    required this.scheduled,
    this.deltaPoints,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (consistency * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // ── Left: label + big percent + trend chip ─────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONSISTENCY',
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    color: kLightGreyColor,
                  ),
                ),
                Space.vertical(6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$percent',
                      style: AppTextStyles.bold.copyWith(
                        fontSize: 52,
                        height: 1.0,
                        color: kPrimaryGreenColor,
                      ),
                    ),
                    Space.horizontal(2),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '%',
                        style: AppTextStyles.semiBold.copyWith(
                          fontSize: 18,
                          color: kPrimaryGreenColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (deltaPoints != null) ...[
                  Space.vertical(10),
                  _TrendChip(deltaPoints: deltaPoints!),
                ],
              ],
            ),
          ),
          Space.horizontal(12),

          // ── Right: progress ring ───────────────────────────────────────────
          _ConsistencyRing(
            progress: consistency,
            completed: completed,
            scheduled: scheduled,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trend chip — "↗ +12% vs last week" (green up / red down / grey flat).
// ─────────────────────────────────────────────────────────────────────────────

class _TrendChip extends StatelessWidget {
  final int deltaPoints;

  const _TrendChip({required this.deltaPoints});

  @override
  Widget build(BuildContext context) {
    final isUp = deltaPoints > 0;
    final isFlat = deltaPoints == 0;
    final color = isFlat
        ? kLightGreyColor
        : isUp
        ? kPrimaryGreenColor
        : kRedColor;
    final sign = isUp ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isFlat
              ? Icons.trending_flat
              : isUp
              ? Icons.trending_up
              : Icons.trending_down,
          size: 16,
          color: color,
        ),
        Space.horizontal(6),
        Text(
          '$sign$deltaPoints%',
          style: AppTextStyles.semiBold.copyWith(fontSize: 13, color: color),
        ),
        Space.horizontal(6),
        Text(
          'vs last week',
          style: AppTextStyles.normal.copyWith(
            fontSize: 13,
            color: kLightGreyColor,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Consistency ring — animated arc with "done OF scheduled" in the center.
// ─────────────────────────────────────────────────────────────────────────────

class _ConsistencyRing extends StatelessWidget {
  final double progress;
  final int completed;
  final int scheduled;

  const _ConsistencyRing({
    required this.progress,
    required this.completed,
    required this.scheduled,
  });

  static const double _size = 108;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _RingPainter(value),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$completed',
                    style: AppTextStyles.bold.copyWith(
                      fontSize: 26,
                      height: 1.0,
                      color: kWhiteColor,
                    ),
                  ),
                  Space.vertical(2),
                  Text(
                    'OF $scheduled',
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: kLightGreyColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter(this.progress);

  static const double _stroke = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - _stroke) / 2;

    // Track.
    final trackPaint = Paint()
      ..color = kBlackColor.withOpacityValue(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc — starts at top (−90°) and sweeps clockwise.
    if (progress > 0) {
      final arcPaint = Paint()
        ..color = kPrimaryGreenColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
