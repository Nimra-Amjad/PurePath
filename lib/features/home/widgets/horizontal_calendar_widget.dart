import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/features/home/models/day_summary.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Training Calendar
//
// A PURE UI widget — it knows nothing about BLoC or business logic.
// All it does:
//   • Render 7 day-tiles for the current page (week)
//   • Draw a circular arc showing habit-completion progress per day
//   • Highlight the selected date with a purple border
//   • Allow swiping between weeks
//   • Fire callbacks when the user taps a day or swipes to a new week
//
// The parent (HomePage) is responsible for:
//   • Providing [weekData] and [selectedDate] from the BLoC state
//   • Dispatching events back to the BLoC via the callbacks
// ─────────────────────────────────────────────────────────────────────────────

class TrainingCalendar extends StatefulWidget {
  /// Habit summaries keyed by date-only DateTime (time = midnight).
  /// Comes directly from HomeState.weekData.
  final Map<DateTime, DaySummary> weekData;

  /// The currently selected date. Comes from HomeState.selectedDate.
  final DateTime selectedDate;

  /// The Monday of the week that the calendar should show as "visible".
  /// Used to derive the month label in the header.
  final DateTime visibleWeekStart;

  /// Called when the user taps a day tile.
  final ValueChanged<DateTime> onDateSelected;

  /// Called when the user swipes to a different week.
  /// Passes the Monday of the newly visible week.
  final ValueChanged<DateTime> onWeekChanged;

  const TrainingCalendar({
    super.key,
    required this.weekData,
    required this.selectedDate,
    required this.visibleWeekStart,
    required this.onDateSelected,
    required this.onWeekChanged,
  });

  @override
  State<TrainingCalendar> createState() => _TrainingCalendarState();
}

class _TrainingCalendarState extends State<TrainingCalendar> {
  // Large center page gives the illusion of infinite scrolling.
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Returns the Monday of the week at [page].
  DateTime _mondayForPage(int page) {
    final today = _dateOnly(DateTime.now());
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    return thisMonday.add(Duration(days: (page - _centerPage) * 7));
  }

  /// Builds 7 [DayTileData] entries for the week starting on [monday].
  List<_DayTileData> _buildTiles(DateTime monday) {
    return List.generate(7, (i) {
      final date = _dateOnly(monday.add(Duration(days: i)));
      final summary = widget.weekData[date];
      return _DayTileData(
        date: date,
        progress: summary?.overallProgress ?? 0.0,
        isSelected: DateUtils.isSameDay(date, widget.selectedDate),
        isToday: DateUtils.isSameDay(date, DateTime.now()),
        isFuture: date.isAfter(_dateOnly(DateTime.now())),
      );
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kBlackColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CalendarHeader(weekStart: widget.visibleWeekStart),
          const SizedBox(height: 14),
          // Fixed height prevents the card from resizing when a tile is selected.
          SizedBox(
            height: 78,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                // Tell the BLoC about the new visible week so it can load data
                // and update the month label.
                widget.onWeekChanged(_mondayForPage(page));
              },
              itemBuilder: (_, page) {
                final monday = _mondayForPage(page);
                final tiles = _buildTiles(monday);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: tiles
                      .map(
                        (tile) => _DayTile(
                          data: tile,
                          onTap: () => widget.onDateSelected(tile.date),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Calendar header  ── "🔥 Daily Streak"  |  "Apr 2026"
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarHeader extends StatelessWidget {
  final DateTime weekStart; // always a Monday

  const _CalendarHeader({required this.weekStart});

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // Shows the month of the week's Monday — so a week spanning March/April
  // correctly shows "Mar 2026" if Monday is in March.
  String get _label =>
      '${_monthNames[weekStart.month - 1]} ${weekStart.year}';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              'Daily Streak',
              style: AppTextStyles.semiBold.copyWith(fontSize: 15),
            ),
          ],
        ),
        Text(
          _label,
          style: AppTextStyles.normal.copyWith(
            fontSize: 13,
            color: kBlackColor.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day tile data  ── plain data class, no Flutter dependency
// ─────────────────────────────────────────────────────────────────────────────

class _DayTileData {
  final DateTime date;
  final double progress; // 0.0 – 1.0
  final bool isSelected;
  final bool isToday;
  final bool isFuture;

  const _DayTileData({
    required this.date,
    required this.progress,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Day tile  ── one circle in the calendar row
// ─────────────────────────────────────────────────────────────────────────────

class _DayTile extends StatelessWidget {
  final _DayTileData data;
  final VoidCallback onTap;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  const _DayTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Highlight today or selected date with purple text.
    final bool highlight = data.isSelected || data.isToday;
    final String dayLabel = _dayLabels[data.date.weekday - 1];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        // Constant padding keeps the PageView height stable.
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        decoration: data.isSelected
            ? BoxDecoration(
                color: lightPurple,
                border: Border.all(color: purple, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              )
            : BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.transparent, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle with arc progress border
            SizedBox(
              width: 36,
              height: 36,
              child: CustomPaint(
                painter: _ArcPainter(
                  progress: data.progress,
                  isFuture: data.isFuture,
                  // Show lightPurple fill only when today and NOT selected
                  // (selected tiles already have the container background).
                  showTodayFill: data.isToday && !data.isSelected,
                ),
                child: Center(
                  child: Text(
                    '${data.date.day}',
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: highlight ? purple : kBlackColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayLabel,
              style: AppTextStyles.normal.copyWith(
                fontSize: 11,
                color: highlight ? purple : kGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arc painter  ── draws the circular progress ring
// ─────────────────────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double progress;
  final bool isFuture;
  final bool showTodayFill;

  const _ArcPainter({
    required this.progress,
    required this.isFuture,
    required this.showTodayFill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 5) / 2;
    const strokeWidth = 2.5;

    // 1. Grey background track (full circle)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = kGreyColor.withValues(alpha: 0.25)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // 2. Light fill for today (only when it's not inside the selected container)
    if (showTodayFill) {
      canvas.drawCircle(
        center,
        radius - strokeWidth / 2,
        Paint()
          ..color = lightPurple
          ..style = PaintingStyle.fill,
      );
    }

    // 3. Purple arc — sweeps clockwise from 12 o'clock proportional to progress
    if (progress > 0 && !isFuture) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // start at 12 o'clock
        2 * math.pi * progress, // sweep angle
        false,
        Paint()
          ..color = purple
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress ||
      old.isFuture != isFuture ||
      old.showTodayFill != showTodayFill;
}
