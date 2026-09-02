import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/planner/models/planner_task.dart';
import 'package:purepath/features/planner/widgets/planner_month_calendar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Planner move sheet — "Move to Date & Time"
//
// Opened from a task card's "Move" menu. Lets the user pick a new day (week
// strip + a month picker behind the calendar icon) and a time (iOS-style
// hour:minute:AM/PM wheel), then hands the choice back through [onMove].
//
// The planner stores tasks by hour, so the minute column is for feel only —
// only the picked hour is applied on save. Pure UI: it never touches the bloc.
// ─────────────────────────────────────────────────────────────────────────────

class PlannerMoveSheet extends StatefulWidget {
  const PlannerMoveSheet({super.key, required this.task, required this.onMove});

  final PlannerTask task;

  /// Fired with the chosen day (local midnight) + hour (0–23) on Apply.
  final void Function(DateTime date, int hour) onMove;

  /// Opens the move sheet for [task].
  static Future<void> show(
    BuildContext context, {
    required PlannerTask task,
    required void Function(DateTime date, int hour) onMove,
  }) {
    return AppBottomSheet.show(
      context,
      body: PlannerMoveSheet(task: task, onMove: onMove),
    );
  }

  @override
  State<PlannerMoveSheet> createState() => _PlannerMoveSheetState();
}

class _PlannerMoveSheetState extends State<PlannerMoveSheet> {
  late DateTime _date;
  late DateTime _time;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _date = _dateOnly(widget.task.date);
    // Seed the wheel at the task's current hour (minutes start at :00).
    _time = DateTime(_date.year, _date.month, _date.day, widget.task.hour);
  }

  void _pickFromCalendar() {
    // Reuse the planner's own month calendar in picker mode — it hands the date
    // back here without touching the planner's own selected date.
    PlannerMonthCalendar.show(
      context,
      selectedDate: _date,
      onDateSelected: (date) => setState(() => _date = _dateOnly(date)),
    );
  }

  void _apply() {
    context.pop();
    widget.onMove(_date, _time.hour);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: title + calendar icon ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Move to Date & Time',
                  style: AppTextStyles.bold.copyWith(
                    fontSize: 24,
                    color: kWhiteColor,
                  ),
                ),
              ),
              Space.horizontal(12),
              _CalendarIconButton(onTap: _pickFromCalendar),
            ],
          ),
          Space.vertical(24),

          // ── Week strip (selected = grey pill, rest transparent) ────────────
          _MoveWeekStrip(
            selectedDate: _date,
            onDateSelected: (date) => setState(() => _date = _dateOnly(date)),
          ),
          Space.vertical(8),

          // ── Time wheel (iOS-style) ─────────────────────────────────────────
          SizedBox(
            height: 200,
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                brightness: Brightness.dark,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    color: kWhiteColor,
                    fontSize: 22,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: false,
                initialDateTime: _time,
                backgroundColor: kTransparentColor,
                onDateTimeChanged: (t) => _time = t,
              ),
            ),
          ),
          Space.vertical(24),

          PrimaryButton(text: 'Apply', onPressed: _apply),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Calendar icon button — a round tile that opens the month date picker.
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarIconButton extends StatelessWidget {
  const _CalendarIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: kContainerColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.calendar_today_rounded,
          color: kWhiteColor,
          size: 20,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Move week strip
//
// A swipeable Monday-first week strip for the move sheet. Unlike the planner's
// main week calendar, it carries no completion rings: the selected day sits in
// a grey pill and every other day is transparent. Infinite paging (a large
// centre page faked both ways) lets the user reach any week; the strip also
// pages itself to follow a date chosen from the calendar icon.
// ─────────────────────────────────────────────────────────────────────────────

class _MoveWeekStrip extends StatefulWidget {
  const _MoveWeekStrip({required this.selectedDate, required this.onDateSelected});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_MoveWeekStrip> createState() => _MoveWeekStripState();
}

class _MoveWeekStripState extends State<_MoveWeekStrip> {
  static const int _centerPage = 500;

  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _pageForDate(widget.selectedDate));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _mondayForPage(int page) {
    final today = _dateOnly(DateTime.now());
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    return thisMonday.add(Duration(days: (page - _centerPage) * 7));
  }

  int _pageForDate(DateTime date) {
    final today = _dateOnly(DateTime.now());
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final monday = _dateOnly(date).subtract(Duration(days: date.weekday - 1));
    final diffDays = DateTime.utc(monday.year, monday.month, monday.day)
        .difference(
          DateTime.utc(thisMonday.year, thisMonday.month, thisMonday.day),
        )
        .inDays;
    return _centerPage + (diffDays ~/ 7);
  }

  /// Follow a date picked from the calendar icon into its week.
  @override
  void didUpdateWidget(covariant _MoveWeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (DateUtils.isSameDay(oldWidget.selectedDate, widget.selectedDate)) return;
    final target = _pageForDate(widget.selectedDate);
    final current = _controller.hasClients
        ? (_controller.page?.round() ?? _centerPage)
        : _centerPage;
    if (target == current) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) _controller.jumpToPage(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: PageView.builder(
        controller: _controller,
        itemBuilder: (_, page) {
          final monday = _mondayForPage(page);
          return Row(
            children: List.generate(7, (i) {
              final date = _dateOnly(monday.add(Duration(days: i)));
              return Expanded(
                child: _MoveDayCell(
                  date: date,
                  isSelected: DateUtils.isSameDay(date, widget.selectedDate),
                  onTap: () => widget.onDateSelected(date),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One day in the move strip — weekday letters over the date number, wrapped in
// a grey pill only when selected.
// ─────────────────────────────────────────────────────────────────────────────

class _MoveDayCell extends StatelessWidget {
  const _MoveDayCell({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  static const _letters = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    final fg = isSelected ? kWhiteColor : kLightGreyColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kContainerColor : kTransparentColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _letters[date.weekday - 1],
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 12,
                color: fg,
                letterSpacing: 0.5,
              ),
            ),
            Space.vertical(8),
            Text(
              '${date.day}',
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 15,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
