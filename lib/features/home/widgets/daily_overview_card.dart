import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/bloc/daily_reflection_bloc.dart';
import 'package:purepath/features/home/models/daily_reflection.dart';
import 'package:purepath/features/home/models/day_summary.dart';
import 'package:purepath/features/home/widgets/daily_reflection_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Daily overview card
//
// One combined card for the top of the home screen:
//
//   ┌──────────────────────────────────────────────┐
//   │   ╭───╮   TODAY'S PROGRESS                     │
//   │   │1/3│   1 of 3 habits                        │
//   │   ╰───╯   2 left · 33% of today                │
//   │  ──────────────────────────────────────────   │
//   │   [😐]  Feeling okay                       ›   │
//   │         Slow start, but got the walk in.       │
//   └──────────────────────────────────────────────┘
//
// The progress ring is drawn by hand ([_ProgressRingPainter]) so its stroke can
// carry a smooth green gradient — something CircularProgressIndicator can't do —
// with the completed fraction sitting in the centre. Below a hairline divider
// sits the day's mood + note; tapping that region opens the reflection sheet.
// ─────────────────────────────────────────────────────────────────────────────

class DailyOverviewCard extends StatelessWidget {
  final DaySummary summary;
  final DateTime date;

  const DailyOverviewCard({
    super.key,
    required this.summary,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kWhiteColor.withOpacityValue(0.05)),
        // Subtle diagonal gradient — a faint lime-tinted charcoal at the top
        // left easing into a deeper charcoal at the bottom right.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D302A), Color(0xFF2A2A2C), Color(0xFF212123)],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(color: kBlackColor.withOpacityValue(0.15), blurRadius: 14),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProgressSection(summary: summary),
          Space.vertical(16),
          Divider(color: kWhiteColor.withOpacityValue(0.06), height: 1),
          Space.vertical(16),
          _ReflectionSection(date: date),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress section — gradient ring + copy
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final DaySummary summary;

  const _ProgressSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final done = summary.completedCount;
    final total = summary.totalCount;
    final remaining = total - done;
    final percent = (summary.overallProgress * 100).round();

    final String subtitle;
    if (total == 0) {
      subtitle = 'Nothing scheduled today';
    } else if (remaining == 0) {
      subtitle = 'All done · 100% of today';
    } else {
      subtitle = '$remaining left · $percent% of today';
    }

    return Row(
      children: [
        _ProgressRing(
          progress: summary.overallProgress,
          completed: done,
          total: total,
        ),
        Space.horizontal(18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TODAY'S PROGRESS",
                style: AppTextStyles.semiBold.copyWith(
                  fontSize: 11.5,
                  color: kLightGreyColor,
                  letterSpacing: 1.2,
                ),
              ),
              Space.vertical(6),
              Text(
                total == 1 ? '$done of $total habit' : '$done of $total habits',
                style: AppTextStyles.bold.copyWith(
                  fontSize: 24,
                  color: kWhiteColor,
                ),
              ),
              Space.vertical(4),
              Text(
                subtitle,
                style: AppTextStyles.normal.copyWith(
                  fontSize: 13,
                  color: kLightGreyColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient progress ring with the completed fraction in the centre
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressRing extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;

  const _ProgressRing({
    required this.progress,
    required this.completed,
    required this.total,
  });

  static const double _size = 86;

  @override
  Widget build(BuildContext context) {
    // TweenAnimationBuilder re-runs from the previously shown value to the new
    // [progress] every time it changes — so ticking a habit off smoothly grows
    // (or shrinks) the arc instead of snapping to the new position.
    return SizedBox(
      width: _size,
      height: _size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeInOutCubic,
        builder: (context, value, child) {
          return CustomPaint(
            painter: _ProgressRingPainter(
              progress: value,
              trackColor: kContainerColorContrast,
              gradientColors: const [kDarkGreenColor, kPrimaryGreenColor],
            ),
            child: child,
          );
        },
        child: Center(
          child: Text(
            '$completed/$total',
            style: AppTextStyles.bold.copyWith(
              fontSize: 16,
              color: kPrimaryGreenColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final List<Color> gradientColors;

  static const double strokeWidth = 7;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    const startAngle = -math.pi / 2; // 12 o'clock

    // Background track — a full faint ring.
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    final clamped = progress.clamp(0.0, 1.0);
    if (clamped <= 0) return;

    final sweep = 2 * math.pi * clamped;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // The sweep gradient spans exactly the drawn arc (start → tip), so the
    // colour eases smoothly from dark green to lime regardless of progress.
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: sweep,
      colors: gradientColors,
      transform: const GradientRotation(startAngle),
    ).createShader(rect);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = shader;

    canvas.drawArc(rect, startAngle, sweep, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.gradientColors != gradientColors;
}

// ─────────────────────────────────────────────────────────────────────────────
// Reflection section — mood + note, tap to edit
// ─────────────────────────────────────────────────────────────────────────────

class _ReflectionSection extends StatelessWidget {
  final DateTime date;

  const _ReflectionSection({required this.date});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailyReflectionBloc, DailyReflectionState>(
      builder: (context, state) {
        final reflection = state.reflectionFor(date) ?? const DailyReflection();
        final accent = reflection.mood?.color ?? kPrimaryGreenColor;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => DailyReflectionSheet.show(
            context,
            date: date,
            initial: reflection,
          ),
          child: reflection.isEmpty
              ? _EmptyReflection(accent: accent)
              : _FilledReflection(reflection: reflection, accent: accent),
        );
      },
    );
  }
}

class _EmptyReflection extends StatelessWidget {
  final Color accent;

  const _EmptyReflection({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconTile(
          accent: accent,
          child: Icon(Icons.edit_note_rounded, color: accent, size: 24),
        ),
        Space.horizontal(14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How are you feeling?',
                style: AppTextStyles.semiBold.copyWith(
                  fontSize: 15,
                  color: kWhiteColor,
                ),
              ),
              Space.vertical(2),
              Text(
                'Log your mood & a note for this day',
                style: AppTextStyles.normal.copyWith(
                  fontSize: 12.5,
                  color: kLightGreyColor,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.add_rounded, color: accent, size: 22),
      ],
    );
  }
}

class _FilledReflection extends StatelessWidget {
  final DailyReflection reflection;
  final Color accent;

  const _FilledReflection({required this.reflection, required this.accent});

  @override
  Widget build(BuildContext context) {
    final mood = reflection.mood;
    final note = reflection.note.trim();

    final title = mood != null
        ? 'Feeling ${mood.label.toLowerCase()}'
        : 'Your note';
    final subtitle = note.isNotEmpty ? note : "Today's reflection";

    return Row(
      children: [
        _IconTile(
          accent: accent,
          child: mood != null
              ? Text(mood.emoji, style: const TextStyle(fontSize: 22))
              : Icon(Icons.sticky_note_2_rounded, color: accent, size: 22),
        ),
        Space.horizontal(14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.semiBold.copyWith(
                  fontSize: 15,
                  color: accent,
                ),
              ),
              Space.vertical(2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.normal.copyWith(
                  fontSize: 13,
                  color: kLightGreyColor,
                ),
              ),
            ],
          ),
        ),
        Space.horizontal(8),
        Icon(Icons.chevron_right_rounded, color: kLightGreyColor, size: 22),
      ],
    );
  }
}

// ── Shared leading tile ───────────────────────────────────────────────────────

class _IconTile extends StatelessWidget {
  final Color accent;
  final Widget child;

  const _IconTile({required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withOpacityValue(0.15),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withOpacityValue(0.25)),
      ),
      child: child,
    );
  }
}
