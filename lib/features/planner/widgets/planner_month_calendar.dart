import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/planner/bloc/planner_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Planner month calendar (bottom sheet)
//
// A full-month grid opened from the calendar icon on the planner header. Each
// date tile carries a completion RING — filled by that day's done ÷ total —
// exactly like the week strip, so a glance shows where the busy/finished days
// are. The selected day sits in a lime tile; today wears a dashed outline.
//
//   • ‹ Month, Year › header pages between months (any month, past or future).
//   • Tapping a date selects it and closes the sheet.
//
// Rebuilds off [PlannerBloc] so rings light up as each month's tasks load.
// ─────────────────────────────────────────────────────────────────────────────

class PlannerMonthCalendar extends StatefulWidget {
  const PlannerMonthCalendar({super.key});

  /// Opens the month calendar as a bottom sheet. Wires the sheet to the caller's
  /// [PlannerBloc] so it can read completion data and dispatch selections.
  static Future<void> show(BuildContext context) {
    final bloc = context.read<PlannerBloc>();
    // Prefetch the currently-selected month so its rings are ready on open.
    bloc.add(PlannerMonthChanged(bloc.state.selectedDate));
    return AppBottomSheet.show(
      context,
      body: BlocProvider.value(
        value: bloc,
        child: const PlannerMonthCalendar(),
      ),
    );
  }

  @override
  State<PlannerMonthCalendar> createState() => _PlannerMonthCalendarState();
}

class _PlannerMonthCalendarState extends State<PlannerMonthCalendar> {
  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const int _firstYear = 1970;
  static const int _lastYear = 2100;

  /// First day of the month currently on screen.
  late DateTime _visibleMonth;

  /// When true a month/year wheel picker overlays the grid.
  bool _showMonthYearPicker = false;

  late final FixedExtentScrollController _monthWheel;
  late final FixedExtentScrollController _yearWheel;

  @override
  void initState() {
    super.initState();
    final selected = context.read<PlannerBloc>().state.selectedDate;
    _visibleMonth = DateTime(selected.year, selected.month, 1);
    _monthWheel = FixedExtentScrollController(
      initialItem: _visibleMonth.month - 1,
    );
    _yearWheel = FixedExtentScrollController(
      initialItem: _visibleMonth.year - _firstYear,
    );
  }

  @override
  void dispose() {
    _monthWheel.dispose();
    _yearWheel.dispose();
    super.dispose();
  }

  void _toggleMonthYearPicker() {
    setState(() => _showMonthYearPicker = !_showMonthYearPicker);
    if (_showMonthYearPicker) {
      // Re-sync the wheels to the month on screen (it may have moved via the
      // side arrows while the picker was closed).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_monthWheel.hasClients) {
          _monthWheel.jumpToItem(_visibleMonth.month - 1);
        }
        if (_yearWheel.hasClients) {
          _yearWheel.jumpToItem(_visibleMonth.year - _firstYear);
        }
      });
    } else {
      // Committing the choice — load the picked month so its rings fill in.
      context.read<PlannerBloc>().add(PlannerMonthChanged(_visibleMonth));
    }
  }

  void _onWheelMonth(int index) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, index + 1, 1);
    });
  }

  void _onWheelYear(int index) {
    setState(() {
      _visibleMonth = DateTime(_firstYear + index, _visibleMonth.month, 1);
    });
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _stepMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
        1,
      );
    });
    // Load the new month's tasks so its rings populate.
    context.read<PlannerBloc>().add(PlannerMonthChanged(_visibleMonth));
  }

  double? _completionFor(PlannerState state, DateTime date) {
    final tasks = state.tasksByDate[_dateOnly(date)];
    if (tasks == null || tasks.isEmpty) return null;
    final done = tasks.where((t) => t.done).length;
    return done / tasks.length;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlannerBloc, PlannerState>(
      builder: (context, state) {
        final today = _dateOnly(DateTime.now());
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Space.vertical(20),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildWeekdayRow(),
                          Space.vertical(8),
                          _buildGrid(state, today),
                        ],
                      ),
                      if (_showMonthYearPicker)
                        Positioned(
                          left: 0,
                          top: 0,
                          // Leave the last two columns (Sat/Sun) peeking out.
                          width: constraints.maxWidth * 5 / 7,
                          child: _buildWheelPicker(),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Header: ‹ August 2026 ▾ › — tap the label to pick a year ──────────────
  Widget _buildHeader() {
    final label =
        '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}';
    return Row(
      children: [
        // Month arrows are disabled while the picker is open.
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: _showMonthYearPicker ? null : () => _stepMonth(-1),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _toggleMonthYearPicker,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bold.copyWith(
                    fontSize: 20,
                    color: kWhiteColor,
                  ),
                ),
                Space.horizontal(4),
                Icon(
                  _showMonthYearPicker
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: kLightGreyColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: _showMonthYearPicker ? null : () => _stepMonth(1),
        ),
      ],
    );
  }

  // ── Month / year wheel picker ─────────────────────────────────────────────
  Widget _buildWheelPicker() {
    const itemExtent = 44.0;
    return Container(
      height: itemExtent * 5,
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kBlackColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Highlight bar behind the centred (selected) row.
          Container(
            height: itemExtent,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: kWhiteColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Wheel(
                  controller: _monthWheel,
                  itemExtent: itemExtent,
                  itemCount: 12,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  labelFor: (i) => _monthNames[i],
                  onChanged: _onWheelMonth,
                ),
              ),
              Expanded(
                child: _Wheel(
                  controller: _yearWheel,
                  itemExtent: itemExtent,
                  itemCount: _lastYear - _firstYear + 1,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  labelFor: (i) => '${_firstYear + i}',
                  onChanged: _onWheelYear,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayRow() {
    return Row(
      children: [
        for (final d in _weekdays)
          Expanded(
            child: Text(
              d,
              textAlign: TextAlign.center,
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 12,
                color: kLightGreyColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }

  // ── The 7-column date grid ─────────────────────────────────────────────────
  //
  // Always six rows (42 cells) so the sheet height never jumps between months.
  // Leading/trailing days from the neighbouring months fill the gaps, dimmed.
  Widget _buildGrid(PlannerState state, DateTime today) {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    // Monday-first: back up to the Monday on/just before the 1st.
    final gridStart = firstOfMonth.subtract(
      Duration(days: firstOfMonth.weekday - 1),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int row = 0; row < 6; row++)
          Row(
            children: [
              for (int col = 0; col < 7; col++)
                Expanded(
                  child: _cellForDate(
                    gridStart.add(Duration(days: row * 7 + col)),
                    state,
                    today,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cellForDate(DateTime date, PlannerState state, DateTime today) {
    final inMonth =
        date.month == _visibleMonth.month && date.year == _visibleMonth.year;
    return _MonthDayCell(
      day: date.day,
      inMonth: inMonth,
      // Rings/today-marker only for the current month's own days.
      completion: inMonth ? _completionFor(state, date) : null,
      isSelected: inMonth && DateUtils.isSameDay(date, state.selectedDate),
      isToday: inMonth && DateUtils.isSameDay(date, today),
      // Neighbouring-month days are display-only (dimmed), not tappable.
      onTap: inMonth
          ? () {
              context.read<PlannerBloc>().add(PlannerDateSelected(date));
              Navigator.of(context).pop();
            }
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header arrow button
// ─────────────────────────────────────────────────────────────────────────────

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;

  /// Null disables (and dims) the arrow — used while the year picker is open.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          color: onTap == null
              ? kLightGreyColor.withValues(alpha: 0.3)
              : kLightGreyColor,
          size: 28,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One scroll wheel (months or years) with a fading, snapping list.
// ─────────────────────────────────────────────────────────────────────────────

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.itemExtent,
    required this.itemCount,
    required this.alignment,
    required this.padding,
    required this.labelFor,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final double itemExtent;
  final int itemCount;
  final Alignment alignment;
  final EdgeInsets padding;
  final String Function(int index) labelFor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemExtent,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.6,
      perspective: 0.003,
      overAndUnderCenterOpacity: 0.35,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (_, i) => Container(
          alignment: alignment,
          padding: padding,
          child: Text(
            labelFor(i),
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 18,
              color: kWhiteColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A single date tile — rounded square, number centred, completion ring behind.
// ─────────────────────────────────────────────────────────────────────────────

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.day,
    required this.inMonth,
    required this.completion,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final int day;

  /// False for neighbouring-month spill-over days (dimmed, non-interactive).
  final bool inMonth;
  final double? completion;
  final bool isSelected;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final numberColor = !inMonth
        ? kLightGreyColor.withValues(alpha: 0.4)
        : isSelected
        ? kScaffoldColor
        : kWhiteColor;
    final fraction = (completion ?? 0).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: !inMonth
              ? kTransparentColor
              : isSelected
              ? kPrimaryGreenColor
              : kContainerColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Today's dashed outline (hidden once the day is selected/filled).
            if (isToday && !isSelected)
              Positioned.fill(
                child: CustomPaint(
                  painter: _DashedBorderPainter(color: kLightGreyColor),
                ),
              ),
            // Completion ring — only for days that actually have tasks.
            if (completion != null)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => CustomPaint(
                  size: const Size(36, 36),
                  painter: _MonthRingPainter(
                    progress: value,
                    // Track hidden on the lime tile; arc flips dark so it reads.
                    showTrack: !isSelected,
                    arcColor: isSelected ? kScaffoldColor : kPrimaryGreenColor,
                  ),
                ),
              ),
            Text(
              '$day',
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 15,
                color: numberColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Completion ring — faint track + arc sweeping clockwise from 12 o'clock.
// ─────────────────────────────────────────────────────────────────────────────

class _MonthRingPainter extends CustomPainter {
  const _MonthRingPainter({
    required this.progress,
    required this.arcColor,
    this.showTrack = true,
  });

  final double progress;
  final Color arcColor;
  final bool showTrack;

  static const double _stroke = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - _stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (showTrack) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..color = kLightGreyColor.withValues(alpha: 0.25),
      );
    }

    if (progress <= 0) return;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..color = arcColor,
    );
  }

  @override
  bool shouldRepaint(_MonthRingPainter old) =>
      old.progress != progress ||
      old.arcColor != arcColor ||
      old.showTrack != showTrack;
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed rounded-rect border — marks "today".
// ─────────────────────────────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  static const double _radius = 16;
  static const double _dash = 4;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(_radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + _dash),
          paint,
        );
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
