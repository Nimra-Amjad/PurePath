import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirstCompletionDialog
//
// One-time celebratory popup shown the moment a user completes their very
// first habit. Unlike [AppDialog] (confirm / cancel), this is a single-CTA
// "moment of delight" — a big emoji, an encouraging message, and one button
// to dismiss. A burst of animated confetti rains down behind the card on show.
// Appears with the same scale + fade motion as the rest of the app.
// ─────────────────────────────────────────────────────────────────────────────

class FirstCompletionDialog extends StatefulWidget {
  const FirstCompletionDialog._();

  /// Shows the celebration. Awaits until the user dismisses it.
  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'first-completion',
      barrierColor: kBlackColor.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
      pageBuilder: (_, __, ___) => const FirstCompletionDialog._(),
    );
  }

  @override
  State<FirstCompletionDialog> createState() => _FirstCompletionDialogState();
}

class _FirstCompletionDialogState extends State<FirstCompletionDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;
  late final List<_Confetto> _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = _buildConfetti();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          // ── Confetti burst (behind the card, ignores taps) ───────────────
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(
                    confetti: _confetti,
                    progress: _confettiController.value,
                  ),
                ),
              ),
            ),
          ),

          // ── The celebration card ─────────────────────────────────────────
          Center(
            child: Material(
              color: kTransparentColor,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  color: kContainerColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: kBlackColor.withValues(alpha: 0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Celebration emblem ───────────────────────────────────
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: kPrimaryGreenColor.withOpacityValue(0.14),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text('🎉', style: TextStyle(fontSize: 38)),
                    ),
                    Space.vertical(18),

                    // ── Title ────────────────────────────────────────────────
                    Text(
                      'Your first win!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bold.copyWith(
                        fontSize: 20,
                        color: kWhiteColor,
                      ),
                    ),
                    Space.vertical(8),

                    // ── Message ──────────────────────────────────────────────
                    Text(
                      'You just completed your very first habit. This is how big '
                      'changes begin — one small win at a time. Keep the momentum '
                      'going! 💪',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 13.5,
                        color: kSecondaryGreyColor,
                        height: 1.5,
                      ),
                    ),
                    Space.vertical(24),

                    // ── Single CTA ───────────────────────────────────────────
                    PrimaryButton(
                      text: "Let's keep going",
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confetti internals
// ─────────────────────────────────────────────────────────────────────────────

/// A single piece of confetti with randomized launch + fall parameters.
/// All positions are expressed as fractions of the screen (0..1) so the
/// painter is resolution-independent.
class _Confetto {
  _Confetto({
    required this.startX,
    required this.horizontalDrift,
    required this.fallDistance,
    required this.delay,
    required this.color,
    required this.size,
    required this.rotationSpeed,
    required this.initialRotation,
  });

  final double startX; // 0..1 across the width
  final double horizontalDrift; // how far it sways sideways (fraction of width)
  final double fallDistance; // how far down it travels (fraction of height)
  final double delay; // 0..1 fraction of timeline before it starts
  final Color color;
  final double size; // logical px
  final double rotationSpeed; // full turns over its lifetime
  final double initialRotation;
}

List<_Confetto> _buildConfetti() {
  final random = math.Random();
  const colors = [
    kPrimaryGreenColor,
    Color(0xFFFFC85C), // warm amber
    Color(0xFF5C9BFF), // sky blue
    Color(0xFFFF6B8A), // pink
    Color(0xFFB98CFF), // violet
    kWhiteColor,
  ];

  return List.generate(46, (i) {
    return _Confetto(
      startX: random.nextDouble(),
      horizontalDrift: (random.nextDouble() - 0.5) * 0.3,
      fallDistance: 0.85 + random.nextDouble() * 0.35,
      delay: random.nextDouble() * 0.25,
      color: colors[random.nextInt(colors.length)],
      size: 6 + random.nextDouble() * 7,
      rotationSpeed: 1 + random.nextDouble() * 3,
      initialRotation: random.nextDouble() * math.pi * 2,
    );
  });
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.confetti, required this.progress});

  final List<_Confetto> confetti;
  final double progress; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final c in confetti) {
      // Local progress for this piece, accounting for its stagger delay.
      final span = 1 - c.delay;
      final t = ((progress - c.delay) / span).clamp(0.0, 1.0);
      if (t <= 0) continue;

      // Ease-out fall so pieces decelerate slightly as they settle.
      final fall = Curves.easeOut.transform(t);

      final dx = (c.startX + c.horizontalDrift * fall) * size.width;
      final dy = (-0.1 + (c.fallDistance + 0.1) * fall) * size.height;

      // Fade out over the last third of the fall.
      final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
      paint.color = c.color.withValues(alpha: opacity);

      final angle = c.initialRotation + c.rotationSpeed * fall * math.pi * 2;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(angle);
      // Rectangular flake; scale height a touch for a "flutter" feel.
      final w = c.size;
      final h = c.size * (0.5 + 0.5 * (math.cos(angle * 2).abs()));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
