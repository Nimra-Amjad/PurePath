import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/habit_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit tile widget
//
// Displays one habit row: a colored accent bar on the left edge, the title,
// the schedule subtitle, and a circular completion badge on the right.
//
// A completed tile is highlighted — a soft accent-tinted gradient washes in
// from the left edge, a faint accent border wraps the card, and the title dims
// to show the day's work is done. An incomplete tile stays flat and dark with a
// bright white title and a hollow outline circle waiting to be tapped.
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

  /// Fades the tile to signal it's read-only — used for future days, which are
  /// viewable but can't be marked done.
  final bool dimmed;

  const HabitTileWidget({
    super.key,
    required this.habit,
    required this.onTap,
    this.dimmed = false,
  });

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
    final color = widget.habit.accentColor;
    final isCompleted = widget.habit.isCompleted;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: widget.dimmed ? 0.45 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Completed tiles glow with a soft accent tint washing in from the
            // left; incomplete tiles stay a flat dark card.
            gradient: isCompleted
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color.alphaBlend(
                        color.withValues(alpha: 0.16),
                        kScaffoldColor,
                      ),
                      kScaffoldColor,
                    ],
                  )
                : null,
            color: isCompleted ? null : kContainerColor,
            border: Border.all(
              color: isCompleted
                  ? color.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.04),
              width: 1,
            ),
            boxShadow: isCompleted
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.10),
                      blurRadius: 16,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // ── Left accent bar ──────────────────────────────────────────
              Container(
                width: 4,
                height: 52,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ),

              // ── Title + streak ───────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.habit.title,
                        style: AppTextStyles.semiBold.copyWith(
                          fontSize: 16,
                          color: isCompleted ? kLightGreyColor : kWhiteColor,
                        ),
                      ),
                      Space.vertical(6),
                      Text(
                        widget.habit.subtitle,
                        style: AppTextStyles.normal.copyWith(
                          fontSize: 13,
                          color: kLightGreyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Completion badge ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _CompletionBadge(
                  controller: _controller,
                  color: color,
                  isCompleted: isCompleted,
                ),
              ),
            ],
          ),
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
//
// Completed → a solid accent disc with a dark check. Incomplete → a hollow
// ring with a faint grey outline, waiting to be tapped.
// A non-clipping [Stack] lets the burst spill past the badge bounds.
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

  static const double _size = 34;

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
              color: isCompleted ? color : kTransparentColor,
              border: isCompleted
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 2,
                    ),
            ),
            child: isCompleted
                ? ScaleTransition(
                    scale: popScale,
                    child: const Icon(
                      Icons.check_rounded,
                      size: 20,
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
    final ringRadius = 17 + eased * 14; // 17 → 31
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * fade
      ..color = color.withValues(alpha: 0.5 * fade);
    if (ringPaint.strokeWidth > 0) {
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // ── Sparkle dots ───────────────────────────────────────────────────────
    final dotDistance = 10 + eased * 18; // 10 → 28
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
