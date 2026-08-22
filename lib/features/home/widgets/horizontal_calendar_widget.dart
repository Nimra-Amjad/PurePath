import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Training Calendar
//
// A PURE UI widget — no BLoC or business logic.
//   • Renders 7 pill-shaped day tiles for the visible week
//   • Highlights the selected date with a filled green pill
//   • Supports infinite swiping between weeks (future weeks blocked)
//   • Fires callbacks when a day is tapped or the week changes
// ─────────────────────────────────────────────────────────────────────────────

class TrainingCalendar extends StatefulWidget {
  /// The currently selected date. Comes from HomeState.selectedDate.
  final DateTime selectedDate;

  /// The Monday of the week the calendar should show as "visible".
  /// Used to derive the month label in the header.
  final DateTime visibleWeekStart;

  /// Called when the user taps a day tile.
  final ValueChanged<DateTime> onDateSelected;

  /// Called when the user swipes to a different week.
  /// Passes the Monday of the newly visible week.
  final ValueChanged<DateTime> onWeekChanged;

  /// Called when the user taps the calendar icon in the header. Null hides the
  /// icon entirely. Used to open the weekly overview sheet.
  final VoidCallback? onOverviewTap;

  const TrainingCalendar({
    super.key,
    required this.selectedDate,
    required this.visibleWeekStart,
    required this.onDateSelected,
    required this.onWeekChanged,
    this.onOverviewTap,
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

  /// Builds 7 [_DayTileData] entries for the week starting on [monday].
  List<_DayTileData> _buildTiles(DateTime monday) {
    return List.generate(7, (i) {
      final date = _dateOnly(monday.add(Duration(days: i)));
      return _DayTileData(
        date: date,
        isSelected: DateUtils.isSameDay(date, widget.selectedDate),
        isFuture: date.isAfter(_dateOnly(DateTime.now())),
      );
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CalendarHeader(
            weekStart: widget.visibleWeekStart,
            onOverviewTap: widget.onOverviewTap,
          ),
          const SizedBox(height: 14),
          // Fixed height prevents the card from resizing when a tile is selected.
          SizedBox(
            height: 80,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                // Block navigation to future weeks — snap back immediately.
                if (page > _centerPage) {
                  _pageController.jumpToPage(_centerPage);
                  return;
                }
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
                          // Future tiles are not tappable.
                          onTap: tile.isFuture
                              ? null
                              : () => widget.onDateSelected(tile.date),
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
// Calendar header  ── "📅 This Week"  |  "Apr 2026"
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarHeader extends StatelessWidget {
  final DateTime weekStart; // always a Monday

  /// Tap handler for the weekly-overview icon. Null hides the icon.
  final VoidCallback? onOverviewTap;

  const _CalendarHeader({required this.weekStart, this.onOverviewTap});

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get _label => '${_monthNames[weekStart.month - 1]} ${weekStart.year}';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (onOverviewTap != null) ...[
          // Weekly-overview entry point — opens the per-habit week sheet.
          GestureDetector(
            onTap: onOverviewTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  'Weekly overview',
                  style: AppTextStyles.medium.copyWith(
                    fontSize: 16,
                    color: kWhiteColor,
                  ),
                ),
                Space.horizontal(6),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: kLightGreyColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
        Text(
          _label,
          style: AppTextStyles.medium.copyWith(
            fontSize: 16,
            color: kWhiteColor,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day tile data
// ─────────────────────────────────────────────────────────────────────────────

class _DayTileData {
  final DateTime date;
  final bool isSelected;
  final bool isFuture;

  const _DayTileData({
    required this.date,
    required this.isSelected,
    required this.isFuture,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Day tile  ── pill with day-name on top and date number below
// ─────────────────────────────────────────────────────────────────────────────

class _DayTile extends StatelessWidget {
  final _DayTileData data;

  /// Null for future dates — disables the tap gesture entirely.
  final VoidCallback? onTap;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  const _DayTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dayLabel = _dayLabels[data.date.weekday - 1];
    final opacity = data.isFuture ? 0.4 : 1.0;
    final isSelected = data.isSelected;

    final foreground = isSelected ? kBlackColor : kWhiteColor;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryGreenColor : kTransparentColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? kPrimaryGreenColor
                  : kLightGreyColor.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dayLabel,
                style: AppTextStyles.medium.copyWith(
                  fontSize: 12,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${data.date.day}',
                style: AppTextStyles.semiBold.copyWith(
                  fontSize: 15,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
