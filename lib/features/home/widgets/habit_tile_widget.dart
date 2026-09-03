import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/habit_model.dart';
import 'package:purepath/features/home/widgets/frequency_badge.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit tile widget
//
// Displays one habit row: category emoji avatar, title, subtitle,
// and an animated checkmark badge.
//
// Tapping fires [onTap] → parent dispatches [HabitToggled] to [HomeBloc],
// which toggles completion and propagates the change to both the calendar
// arc and the daily progress card automatically.
//
// When the habit flips to *completed*, a one-shot celebration plays around
// the badge (a radiating ring, sparkles, and a springy check "pop") plus a
// light haptic tap. The transition is detected in [didUpdateWidget] so the
// animation fires off the real bloc state change, never a local guess.
// ─────────────────────────────────────────────────────────────────────────────

class HabitTileWidget extends StatefulWidget {
  final HabitModel habit;

  /// Called when the tile is tapped.
  /// Parent is responsible for dispatching [HabitToggled] to [HomeBloc].
  final VoidCallback onTap;

  const HabitTileWidget({super.key, required this.habit, required this.onTap});

  @override
  State<HabitTileWidget> createState() => _HabitTileWidgetState();
}

class _HabitTileWidgetState extends State<HabitTileWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      // Start "settled" when the habit is already done so a check that's
      // simply rebuilt (e.g. returning to the tab) shows at full size with
      // no burst — only a fresh completion runs the animation from zero.
      value: widget.habit.isCompleted ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant HabitTileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final was = oldWidget.habit.isCompleted;
    final now = widget.habit.isCompleted;

    if (!was && now) {
      // Just completed → celebrate.
      HapticFeedback.mediumImpact();
      _controller.forward(from: 0);
    } else if (was && !now) {
      // Un-completed → reset silently so the next completion animates again.
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const color = kHabitAccentColor;
    const emoji = kHabitEmoji;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kContainerColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Category emoji inside a tinted circle
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacityValue(0.15),
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            Space.horizontal(12),

            // Title, subtitle, and frequency badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.habit.title,
                    style: AppTextStyles.bold.copyWith(color: kWhiteColor),
                  ),
                  Space.vertical(3),
                  Text(
                    widget.habit.subtitle,
                    style: AppTextStyles.normal.copyWith(
                      color: kSecondaryGreyColor,
                    ),
                  ),
                  Space.vertical(5),
                  FrequencyBadge(
                    label: widget.habit.frequencyLabel,
                    color: color,
                  ),
                ],
              ),
            ),
            Space.horizontal(12),

            // Checkmark badge with completion celebration.
            _CompletionBadge(
              controller: _controller,
              color: color,
              isCompleted: widget.habit.isCompleted,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Completion badge
//
// The circular check badge plus its celebration overlay. Drives everything
// from a single [controller] (0 → 1):
//   • a radiating ring that expands and fades,
//   • sparkle dots that shoot outward,
//   • the check icon springing in with an elastic "pop".
// A non-clipping [Stack] lets the burst spill past the 28×28 badge bounds.
// ─────────────────────────────────────────────────────────────────────────────

class _CompletionBadge extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final bool isCompleted;

  const _CompletionBadge({
    required this.controller,
    required this.color,
    required this.isCompleted,
  });

  static const double _size = 28;

  @override
  Widget build(BuildContext context) {
    final popScale = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Burst overlay (ring + sparkles) ──────────────────────────────
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              if (!controller.isAnimating) return const SizedBox.shrink();
              return CustomPaint(
                size: const Size(_size, _size),
                painter: _BurstPainter(
                  progress: controller.value,
                  color: color,
                ),
              );
            },
          ),

          // ── The badge itself ─────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? color : kWhiteColor,
            ),
            child: isCompleted
                ? ScaleTransition(
                    scale: popScale,
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: kBlackColor,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Burst painter
//
// Paints the expanding ring and the outward-flying sparkle dots for one frame
// of the celebration, given [progress] (0 → 1).
// ─────────────────────────────────────────────────────────────────────────────

class _BurstPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _BurstPainter({required this.progress, required this.color});

  static const int _sparkleCount = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOut.transform(progress);
    final fade = (1.0 - progress).clamp(0.0, 1.0);

    // ── Expanding ring ─────────────────────────────────────────────────────
    final ringRadius = 14 + eased * 12; // 14 → 26
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * fade
      ..color = color.withValues(alpha: 0.5 * fade);
    if (ringPaint.strokeWidth > 0) {
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // ── Sparkle dots ───────────────────────────────────────────────────────
    final dotDistance = 8 + eased * 16; // 8 → 24
    final dotRadius = 2.4 * fade;
    final dotPaint = Paint()..color = color.withValues(alpha: fade);
    if (dotRadius > 0) {
      for (var i = 0; i < _sparkleCount; i++) {
        final angle = (2 * math.pi / _sparkleCount) * i - math.pi / 2;
        final dx = center.dx + math.cos(angle) * dotDistance;
        final dy = center.dy + math.sin(angle) * dotDistance;
        canvas.drawCircle(Offset(dx, dy), dotRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
