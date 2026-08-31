import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Planner week calendar
//
// A horizontal week strip styled after the reference "activity" calendar:
//   • One vertical capsule per day — a single day-letter on top, the date number
//     inside a circle below.
//   • The selected day sits inside a tall filled capsule.
//   • Every date circle carries a progress RING that fills based on that day's
//     task-completion percentage (done ÷ total). No tasks → just an empty track.
//   • Infinite week swiping (the planner allows planning any week, past or
//     future).
//
// Pure UI — no BLoC. Completion fractions are supplied by [completionFor] and
// day-tap / week-swipe are delegated up through callbacks.
// ─────────────────────────────────────────────────────────────────────────────

class PlannerWeekCalendar extends StatefulWidget {
  /// The currently selected day (PlannerState.selectedDate).
  final DateTime selectedDate;

  /// Called when the user taps a day.
  final ValueChanged<DateTime> onDateSelected;

  /// Called when the user swipes to a new week — passes that week's Monday.
  final ValueChanged<DateTime> onWeekChanged;

  /// Completion fraction in [0, 1] for [date], or null when the day has no
  /// tasks (or hasn't loaded yet). Null renders the empty track only.
  final double? Function(DateTime date) completionFor;

  const PlannerWeekCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onWeekChanged,
    required this.completionFor,
  });

  @override
  State<PlannerWeekCalendar> createState() => _PlannerWeekCalendarState();
}

class _PlannerWeekCalendarState extends State<PlannerWeekCalendar> {
  // Large center page fakes an infinite scroll in both directions.
  static const int _centerPage = 500;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _centerPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The Monday of the week shown at [page].
  DateTime _mondayForPage(int page) {
    final today = _dateOnly(DateTime.now());
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    return thisMonday.add(Duration(days: (page - _centerPage) * 7));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) => widget.onWeekChanged(_mondayForPage(page)),
        itemBuilder: (_, page) {
          final monday = _mondayForPage(page);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final date = _dateOnly(monday.add(Duration(days: i)));
              return _DayCapsule(
                date: date,
                isSelected: DateUtils.isSameDay(date, widget.selectedDate),
                completion: widget.completionFor(date),
                onTap: () => widget.onDateSelected(date),
              );
            }),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day capsule — day-letter on top, date circle (with completion ring) below.
// ─────────────────────────────────────────────────────────────────────────────

class _DayCapsule extends StatelessWidget {
  const _DayCapsule({
    required this.date,
    required this.isSelected,
    required this.completion,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final double? completion;
  final VoidCallback onTap;

  // Single-letter labels, Monday-first (the app's weeks start on Monday).
  static const _letters = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final letter = _letters[date.weekday - 1];

    // Foregrounds flip on the selected capsule so text stays legible on lime.
    final letterColor = isSelected ? kScaffoldColor : kLightGreyColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryGreenColor : kContainerColor,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              letter,
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 13,
                color: letterColor,
              ),
            ),
            Space.vertical(8),
            _DateCircle(
              day: date.day,
              completion: completion,
              // On the lime capsule the disc goes dark so the ring + number
              // read clearly; off it, a slightly-raised container tint.
              fillColor: isSelected ? kScaffoldColor : kContainerColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date circle — a disc with the date number, wrapped by a completion ring.
// ─────────────────────────────────────────────────────────────────────────────

class _DateCircle extends StatelessWidget {
  const _DateCircle({
    required this.day,
    required this.completion,
    required this.fillColor,
  });

  final int day;
  final double? completion;
  final Color fillColor;

  static const double _size = 45;

  @override
  Widget build(BuildContext context) {
    final fraction = (completion ?? 0).clamp(0.0, 1.0);

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Disc behind the number.
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(color: fillColor, shape: BoxShape.circle),
          ),
          // Completion ring (empty track + lime progress arc).
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => CustomPaint(
              size: const Size(_size, _size),
              painter: _RingPainter(progress: value),
            ),
          ),
          Text(
            '$day',
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 14,
              color: kWhiteColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring painter — a full faint track plus a lime arc sweeping from 12 o'clock
// clockwise, its length equal to the completion fraction.
// ─────────────────────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  /// Completion fraction in [0, 1].
  final double progress;

  static const double _stroke = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - _stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Empty track.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = kLightGreyColor.withValues(alpha: 0.25),
    );

    if (progress <= 0) return;

    // Progress arc — starts at the top, sweeps clockwise, rounded cap.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..color = kPrimaryGreenColor,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
