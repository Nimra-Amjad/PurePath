import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WelcomePage
//
// Single dark cinematic landing screen shown right after onboarding finishes.
// The page never auto-advances — the user enters the app on their own tap.
//
// Three loops drive the feel:
//   • Ambient glow — slow kPurpleColor → green radial swap behind the logo (~6s).
//   • Logo breath — gentle scale pulse (~3s).
//   • Entry fade — one-shot staggered fade + slide-up for title, tagline, CTA.
// ─────────────────────────────────────────────────────────────────────────────

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final AnimationController _breatheCtrl;
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _breatheCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _goToApp() => context.go(AppRoute.bottomNavBar.path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldColor,
      body: Stack(
        children: [
          Positioned.fill(child: _AmbientGlow(controller: _glowCtrl)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  _BreathingLogo(controller: _breatheCtrl),
                  Space.vertical(36),
                  _EntryFade(
                    controller: _entryCtrl,
                    intervalStart: 0.2,
                    child: Text(
                      'PurePath',
                      style: AppTextStyles.bold.copyWith(
                        fontSize: 36,
                        color: kWhiteColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Space.vertical(14),
                  _EntryFade(
                    controller: _entryCtrl,
                    intervalStart: 0.35,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'A quiet space where small daily habits slowly become who you are.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.normal.copyWith(
                          fontSize: 14.5,
                          color: kSecondaryGreyColor,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 6),
                  _EntryFade(
                    controller: _entryCtrl,
                    intervalStart: 0.55,
                    child: PrimaryButton(
                      text: 'Get Started',
                      onPressed: _goToApp,
                      height: 54,
                      borderRadius: 16,
                      postfixIcon: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: kBlackColor,
                      ),
                      isSpaceBetween: false,
                    ),
                  ),
                  Space.vertical(16),
                  _EntryFade(
                    controller: _entryCtrl,
                    intervalStart: 0.72,
                    child: Text(
                      'SMALL HABITS · BIG CHANGE',
                      style: AppTextStyles.medium.copyWith(
                        fontSize: 11,
                        color: kSecondaryGreyColor,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ambient glow — slow kPurpleColor → green radial swap
// ─────────────────────────────────────────────────────────────────────────────

class _AmbientGlow extends StatelessWidget {
  final AnimationController controller;
  const _AmbientGlow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(controller.value);
        final color =
            Color.lerp(kPurpleColor, kDarkGreenColor, t) ?? kPurpleColor;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.4),
              radius: 1.0,
              colors: [
                color.withValues(alpha: 0.38),
                color.withValues(alpha: 0.10),
                kScaffoldColor,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Breathing logo — soft scale loop inside a tinted disc
// ─────────────────────────────────────────────────────────────────────────────

class _BreathingLogo extends StatelessWidget {
  final AnimationController controller;
  const _BreathingLogo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(controller.value);
        final scale = 0.96 + 0.04 * t;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kContainerColor.withValues(alpha: 0.5),
          border: Border.all(
            color: kWhiteColor.withValues(alpha: 0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: kPurpleColor.withValues(alpha: 0.18),
              blurRadius: 48,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: SvgPicture.asset(Assets.svgSplashLogo),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry fade — staggered fade-in + small slide-up keyed off one controller
// ─────────────────────────────────────────────────────────────────────────────

class _EntryFade extends StatelessWidget {
  final AnimationController controller;
  final double intervalStart;
  final Widget child;

  const _EntryFade({
    required this.controller,
    required this.intervalStart,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(intervalStart, 1.0, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) {
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * 14),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}
