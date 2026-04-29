import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/navigation/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WelcomePage
//
// Shown right after the user taps "Allow notifications" or "Skip" in onboarding.
// Plays through 4 animated slides automatically (~1.8 s each → ~7.2 s total),
// then navigates to the main app.
// ─────────────────────────────────────────────────────────────────────────────

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

// ── Slide data ─────────────────────────────────────────────────────────────

class _Slide {
  final String emoji;
  final String headline;
  final String subtitle;
  final List<Color> colors; // gradient stops

  const _Slide({
    required this.emoji,
    required this.headline,
    required this.subtitle,
    required this.colors,
  });
}

const _slides = [
  _Slide(
    emoji: '🌿',
    headline: 'Welcome to PurePath',
    subtitle: 'A place where better habits slowly become your identity.',
    colors: [Color(0xFFEDE9FF), Color(0xFFD6CCFF)],
  ),
  _Slide(
    emoji: '🔥',
    headline: 'Build habits that stick',
    subtitle:
        'Check in daily, grow your streak, and never lose momentum again.',
    colors: [Color(0xFFE8F4FF), Color(0xFFD0E8FF)],
  ),
  _Slide(
    emoji: '🏅',
    headline: 'Earn rewards as you grow',
    subtitle:
        'Unlock badges, level up your tier, and celebrate every milestone.',
    colors: [Color(0xFFFFF3E8), Color(0xFFFFE4CC)],
  ),
  _Slide(
    emoji: '💜',
    headline: "Your journey starts now",
    subtitle: 'Small habits. Big change. Let\'s build your pure path together.',
    colors: [Color(0xFFEDE9FF), Color(0xFFDDD6FF)],
  ),
];

// ── State ──────────────────────────────────────────────────────────────────

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // Progress of the *current* slide's fill (0 → 1 over 1.8 s)
  double _slotProgress = 0.0;
  Timer? _progressTimer;

  static const _slideDuration = Duration(milliseconds: 1800);
  static const _tickInterval = Duration(milliseconds: 16); // ~60 fps

  @override
  void initState() {
    super.initState();
    _startSlide();
  }

  void _startSlide() {
    _slotProgress = 0.0;
    _progressTimer?.cancel();

    final totalTicks = _slideDuration.inMilliseconds / _tickInterval.inMilliseconds;

    _progressTimer = Timer.periodic(_tickInterval, (t) {
      if (!mounted) return;
      setState(() => _slotProgress = (t.tick / totalTicks).clamp(0.0, 1.0));
    });

    _timer = Timer(_slideDuration, _advance);
  }

  void _advance() {
    _progressTimer?.cancel();
    _timer?.cancel();

    if (!mounted) return;

    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      // onPageChanged fires _startSlide after transition
    } else {
      _goToApp();
    }
  }

  void _goToApp() {
    _progressTimer?.cancel();
    _timer?.cancel();
    if (mounted) context.go(AppRoute.bottomNavBar.path);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ── Progress bar ──────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: List.generate(_slides.length, (i) {
          final isActive = i == _currentPage;
          final isDone = i < _currentPage;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < _slides.length - 1 ? 6 : 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 3,
                  child: Stack(
                    children: [
                      // Track
                      Container(color: const Color(0xFF6C4DFF).withValues(alpha: 0.18)),
                      // Fill
                      FractionallySizedBox(
                        widthFactor: isDone ? 1.0 : (isActive ? _slotProgress : 0.0),
                        alignment: Alignment.centerLeft,
                        child: Container(color: const Color(0xFF6C4DFF)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: slide.colors,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Progress bars ────────────────────────────────────────────
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: _buildProgressBar(),
              ),

              // ── Slide content ────────────────────────────────────────────
              PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  _startSlide();
                },
                itemCount: _slides.length,
                itemBuilder: (_, index) => _SlideView(slide: _slides[index]),
              ),

              // ── Bottom hint ──────────────────────────────────────────────
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _currentPage == _slides.length - 1 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      'Taking you in…',
                      style: AppTextStyles.normal.copyWith(
                        color: const Color(0xFF6C4DFF).withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ),
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
// _SlideView — animates in when mounted
// ─────────────────────────────────────────────────────────────────────────────

class _SlideView extends StatefulWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  State<_SlideView> createState() => _SlideViewState();
}

class _SlideViewState extends State<_SlideView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _emojiScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );

    _emojiScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
    );

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 1.0, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.30, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji
            ScaleTransition(
              scale: _emojiScale,
              child: Text(
                widget.slide.emoji,
                style: const TextStyle(fontSize: 88),
              ),
            ),

            const SizedBox(height: 36),

            // Headline + subtitle
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  children: [
                    Text(
                      widget.slide.headline,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bold.copyWith(
                        fontSize: 28,
                        color: const Color(0xFF2D1F6E),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.slide.subtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 15,
                        color: const Color(0xFF2D1F6E).withValues(alpha: 0.65),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
