import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/custom_textfield.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/habit_definition.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared habit-form fields
//
// One source of truth for the "New Habit" / "Edit Habit" / configure-predefined
// form so all three screens stay identical: Task days (Every day / Specific
// weekdays / Specific month dates), the reminder toggle + time, and the habit
// term (start/end) date range. Keeping these here avoids the three-way copy the
// screens used to carry.
// ─────────────────────────────────────────────────────────────────────────────

/// The habit name field with a sparkle prefix, shared by Add/Edit screens.
class HabitNameField extends StatelessWidget {
  final TextEditingController controller;
  const HabitNameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return HabitFormSection(
      label: 'HABIT NAME',
      child: CustomTextField(
        controller: controller,
        hintText: 'e.g. Read 20 pages',
        textCapitalization: TextCapitalization.sentences,
        inputFormatters: [LengthLimitingTextInputFormatter(50)],
        prefix: const Icon(
          Icons.auto_awesome_rounded,
          color: kPrimaryGreenColor,
          size: 18,
        ),
        validator: (value) {
          final v = value?.trim() ?? '';
          if (v.isEmpty) return 'Please enter a habit name';
          if (v.length < 2) return 'Name must be at least 2 characters';
          return null;
        },
      ),
    );
  }
}

/// Wraps a form section with a small uppercase label above its content.
class HabitFormSection extends StatelessWidget {
  final String label;
  final Widget child;

  const HabitFormSection({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.semiBold.copyWith(
            fontSize: 11,
            letterSpacing: 1.1,
            color: kWhiteColor,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task days — the schedule picker (Every day / Weekdays / Month dates)
// ─────────────────────────────────────────────────────────────────────────────

class TaskDaysSection extends StatelessWidget {
  final HabitSchedule schedule;
  final Set<int> selectedWeekDays; // 0 = Mon … 6 = Sun
  final Set<int> selectedMonthDays; // 1 … 31
  final bool weekDayError;
  final bool monthDayError;
  final ValueChanged<HabitSchedule> onScheduleChanged;
  final ValueChanged<int> onWeekDayToggled;
  final ValueChanged<int> onMonthDayToggled;

  const TaskDaysSection({
    super.key,
    required this.schedule,
    required this.selectedWeekDays,
    required this.selectedMonthDays,
    required this.weekDayError,
    required this.monthDayError,
    required this.onScheduleChanged,
    required this.onWeekDayToggled,
    required this.onMonthDayToggled,
  });

  @override
  Widget build(BuildContext context) {
    return HabitFormSection(
      label: 'TASK DAYS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TaskDayOption(
            title: 'Every day',
            trailing: '7 / week',
            selected: schedule == HabitSchedule.everyDay,
            onTap: () => onScheduleChanged(HabitSchedule.everyDay),
          ),
          const SizedBox(height: 10),
          _TaskDayOption(
            title: 'Specific days of the week',
            selected: schedule == HabitSchedule.weekDays,
            onTap: () => onScheduleChanged(HabitSchedule.weekDays),
          ),
          if (schedule == HabitSchedule.weekDays) ...[
            const SizedBox(height: 12),
            _WeekDayPicker(
              selected: selectedWeekDays,
              onToggle: onWeekDayToggled,
            ),
            if (weekDayError) ...[
              const SizedBox(height: 6),
              const _ErrorLabel('Please select at least one day'),
            ],
          ],
          const SizedBox(height: 10),
          _TaskDayOption(
            title: 'Specific dates of the month',
            selected: schedule == HabitSchedule.monthDays,
            onTap: () => onScheduleChanged(HabitSchedule.monthDays),
          ),
          if (schedule == HabitSchedule.monthDays) ...[
            const SizedBox(height: 12),
            _MonthDayGrid(
              selected: selectedMonthDays,
              onToggle: onMonthDayToggled,
            ),
            if (monthDayError) ...[
              const SizedBox(height: 6),
              const _ErrorLabel('Please select at least one date'),
            ],
          ],
        ],
      ),
    );
  }
}

class _TaskDayOption extends StatelessWidget {
  final String title;
  final String? trailing;
  final bool selected;
  final VoidCallback onTap;

  const _TaskDayOption({
    required this.title,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? kPrimaryGreenColor.withValues(alpha: 0.10)
              : kContainerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? kPrimaryGreenColor
                : kSecondaryGreyColor.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _RadioDot(selected: selected),
            Space.horizontal(12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.semiBold.copyWith(
                  fontSize: 14,
                  color: kWhiteColor,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: AppTextStyles.normal.copyWith(
                  fontSize: 12,
                  color: kSecondaryGreyColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? kPrimaryGreenColor : kSecondaryGreyColor,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryGreenColor,
                ),
              ),
            )
          : null,
    );
  }
}

class _WeekDayPicker extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  const _WeekDayPicker({required this.selected, required this.onToggle});

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(7, (i) {
        final isSelected = selected.contains(i);
        return GestureDetector(
          onTap: () => onToggle(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? kDarkGreenColor : kWhiteColor,
            ),
            child: Center(
              child: Text(
                _labels[i],
                style: AppTextStyles.normal.copyWith(
                  fontSize: 12,
                  color: isSelected ? kWhiteColor : kBlackColor,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _MonthDayGrid extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  const _MonthDayGrid({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(31, (i) {
        final day = i + 1;
        final isSelected = selected.contains(day);
        return GestureDetector(
          onTap: () => onToggle(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? kDarkGreenColor : kContainerColor,
              border: Border.all(
                color: isSelected
                    ? kDarkGreenColor
                    : kSecondaryGreyColor.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                '$day',
                style: AppTextStyles.medium.copyWith(
                  fontSize: 13,
                  color: isSelected ? kWhiteColor : kLightGreyColor,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reminder — an on/off switch and a single optional time.
// ─────────────────────────────────────────────────────────────────────────────

class ReminderSection extends StatelessWidget {
  final bool enabled;
  final TextEditingController timeController;
  final bool showError;
  final ValueChanged<bool> onToggled;
  final VoidCallback onPickTime;

  const ReminderSection({
    super.key,
    required this.enabled,
    required this.timeController,
    required this.showError,
    required this.onToggled,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    return HabitFormSection(
      label: 'REMINDER',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: kContainerColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: kSecondaryGreyColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Reminders',
                    style: AppTextStyles.semiBold.copyWith(
                      fontSize: 14,
                      color: kWhiteColor,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: enabled,
                  onChanged: onToggled,
                  activeTrackColor: kPrimaryGreenColor,
                  activeThumbColor: kWhiteColor,
                ),
              ],
            ),
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            CustomTextField(
              controller: timeController,
              hintText: 'Pick a reminder time',
              readOnly: true,
              onTap: onPickTime,
              suffix: const Icon(
                Icons.access_time_rounded,
                color: kGreyColor,
                size: 20,
              ),
            ),
            if (showError) ...[
              const SizedBox(height: 6),
              const _ErrorLabel('Please pick a reminder time'),
            ],
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit term — start / end date range.
// ─────────────────────────────────────────────────────────────────────────────

class HabitTermSection extends StatelessWidget {
  final DateTime startDate;
  final DateTime? endDate;
  final bool showError;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback? onClearEnd;

  const HabitTermSection({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.showError,
    required this.onPickStart,
    required this.onPickEnd,
    this.onClearEnd,
  });

  @override
  Widget build(BuildContext context) {
    return HabitFormSection(
      label: 'HABIT TERM',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Start date',
                  date: startDate,
                  onTap: onPickStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'End date',
                  date: endDate,
                  hint: 'No end',
                  onTap: onPickEnd,
                  onClear: onClearEnd,
                ),
              ),
            ],
          ),
          if (showError) ...[
            const SizedBox(height: 6),
            const _ErrorLabel('End date must be on or after start date'),
          ],
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
    this.hint = 'Pick a date',
    this.onClear,
  });

  String _format(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: kContainerColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kSecondaryGreyColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.medium.copyWith(
                fontSize: 11,
                color: kSecondaryGreyColor,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? _format(date!) : hint,
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: hasValue ? kPrimaryGreenColor : kSecondaryGreyColor,
                    ),
                  ),
                ),
                if (onClear != null && hasValue)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: kGreyColor,
                    ),
                  )
                else
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: kGreyColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorLabel extends StatelessWidget {
  final String text;
  const _ErrorLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.normal.copyWith(fontSize: 12, color: kRedColor),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared bottom-sheet pickers (time + date).
// ─────────────────────────────────────────────────────────────────────────────

/// Opens the reminder time picker; resolves to the chosen [DateTime] (date part
/// irrelevant) or null if dismissed.
Future<DateTime?> showHabitTimePicker(BuildContext context) async {
  final now = DateTime.now();
  DateTime tempPicked =
      DateTime(now.year, now.month, now.day, now.hour, now.minute);

  final confirmed = await AppBottomSheet.show<bool>(
    context,
    backgroundColor: kContainerColor,
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Reminder Time',
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 15,
                color: kWhiteColor,
              ),
            ),
          ),
          Space.vertical(8),
          SizedBox(
            height: 220,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: tempPicked,
              use24hFormat: false,
              onDateTimeChanged: (value) => tempPicked = value,
            ),
          ),
          Space.vertical(8),
          PrimaryButton(text: 'Add Time', onPressed: () => context.pop(true)),
          Space.vertical(32),
        ],
      ),
    ),
  );

  return confirmed == true ? tempPicked : null;
}

/// Opens a date picker between [firstDate] and five years out; resolves to the
/// chosen date (time stripped) or null if dismissed.
Future<DateTime?> showHabitDatePicker(
  BuildContext context, {
  required String title,
  required DateTime initial,
  required DateTime firstDate,
}) async {
  final lastDate = DateTime.now().add(const Duration(days: 365 * 5));
  DateTime tempPicked = initial.isBefore(firstDate)
      ? firstDate
      : (initial.isAfter(lastDate) ? lastDate : initial);

  final confirmed = await AppBottomSheet.show<bool>(
    context,
    backgroundColor: kContainerColor,
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 15,
                color: kWhiteColor,
              ),
            ),
          ),
          Space.vertical(8),
          SizedBox(
            height: 220,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: tempPicked,
              minimumDate: firstDate,
              maximumDate: lastDate,
              onDateTimeChanged: (value) => tempPicked = value,
            ),
          ),
          Space.vertical(8),
          PrimaryButton(text: 'Set Date', onPressed: () => context.pop(true)),
          Space.vertical(32),
        ],
      ),
    ),
  );

  if (confirmed == true) {
    return DateTime(tempPicked.year, tempPicked.month, tempPicked.day);
  }
  return null;
}
