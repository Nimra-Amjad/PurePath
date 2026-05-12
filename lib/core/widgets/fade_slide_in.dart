import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FadeSlideIn
//
// Plays a one-shot fade + slide-up animation on first build. Designed for
// staggering items on a screen entrance — pass an increasing [delay] for each
// element so they cascade into view.
//
// Example:
//   FadeSlideIn(delay: Duration(milliseconds: 0),   child: logo),
//   FadeSlideIn(delay: Duration(milliseconds: 80),  child: title),
//   FadeSlideIn(delay: Duration(milliseconds: 160), child: emailField),
//
// Cheap by design: a single AnimationController per instance and no rebuilds
// after the animation completes.
// ─────────────────────────────────────────────────────────────────────────────

class FadeSlideIn extends StatefulWidget {
  final Widget child;

  /// How long after first build the animation should start. Use larger
  /// values further down the screen to create a staggered cascade.
  final Duration delay;

  /// Total length of the fade + slide. Defaults to 500ms which feels
  /// brisk without being snappy.
  final Duration duration;

  /// Vertical offset (in logical pixels) the child slides up from.
  /// Defaults to 18 — enough to feel like motion, small enough to stay
  /// subtle.
  final double offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 18,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Defer forward() so the parent finishes its first frame before the
    // animation starts — avoids stutter when the route's own transition
    // is still settling.
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(offset: _slide.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}
