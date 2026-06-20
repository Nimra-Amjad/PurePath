import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/custom_textfield.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/home/models/habit_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Configure Predefined Habit Sheet
//
// Shown when the user taps a habit in the Habit Library. The category and title
// come from the library entry and can't be changed — only the schedule details
// are configurable here:
//
//   Frequency (Daily / Weekly) → Date range → Reminder (optional)
//
// On "Add Habit" the sheet pops with a fully-built [HabitDefinition] tagged as
// [HabitType.predefined]. The caller is responsible for persisting it.
// ─────────────────────────────────────────────────────────────────────────────

class ConfigurePredefinedHabitSheet extends StatefulWidget {
  const ConfigurePredefinedHabitSheet({
    super.key,
    required this.category,
    required this.title,
  });

  final HabitCategory category;
  final String title;

  /// Opens the sheet and resolves to a configured [HabitDefinition], or null if
  /// the user dismissed it without confirming.
  static Future<HabitDefinition?> show(
    BuildContext context, {
    required HabitCategory category,
    required String title,
  }) {
    return AppBottomSheet.show<HabitDefinition>(
      context,
      backgroundColor: kScaffoldColor,
      body: ConfigurePredefinedHabitSheet(category: category, title: title),
    );
  }

  @override
  State<ConfigurePredefinedHabitSheet> createState() =>
      _ConfigurePredefinedHabitSheetState();
}

class _ConfigurePredefinedHabitSheetState
    extends State<ConfigurePredefinedHabitSheet> {
  final _reminderController = TextEditingController();

  bool _isDaily = true;
  final Set<int> _selectedWeekDays = {}; // 0 = Mon … 6 = Sun

  late DateTime _startDate = _today();
  DateTime? _endDate;

  bool _weekDayError = false;
  bool _dateRangeError = false;

  static const _weekDayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _reminderController.dispose();
    super.dispose();
  }

  // ── Confirm ────────────────────────────────────────────────────────────────

  void _onConfirm() {
    setState(() {
      _weekDayError = !_isDaily && _selectedWeekDays.isEmpty;
      _dateRangeError = _endDate != null && _endDate!.isBefore(_startDate);
    });

    if (_weekDayError || _dateRangeError) return;

    final weekDays = _isDaily
        ? const <int>[]
        : (_selectedWeekDays.toList()..sort());

    final definition = HabitDefinition(
      id: '', // Firestore assigns a unique id.
      title: widget.title,
      category: widget.category,
      type: HabitType.predefined,
      isDaily: _isDaily,
      weekDays: weekDays,
      reminderTime: _reminderController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
    );

    context.pop(definition);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final categoryColor = widget.category.color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: habit being added ──────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: categoryColor.withValues(alpha: 0.2),
                child: Text(
                  widget.category.emoji,
                  style: const TextStyle(fontSize: 17),
                ),
              ),
              Space.horizontal(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTextStyles.semiBold.copyWith(
                        fontSize: 15,
                        color: kWhiteColor,
                      ),
                    ),
                    Text(
                      widget.category.label,
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 12,
                        color: kLightGreyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildFrequencySection(),
          const SizedBox(height: 24),
          _buildDateRangeSection(),
          const SizedBox(height: 24),
          _buildReminderSection(),
          const SizedBox(height: 28),

          PrimaryButton(text: 'Add Habit', onPressed: _onConfirm),
        ],
      ),
    );
  }

  // ── Section: Frequency ─────────────────────────────────────────────────────

  Widget _buildFrequencySection() {
    return _Section(
      label: 'FREQUENCY',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _FrequencyButton(
                  label: 'Daily',
                  sublabel: 'Every day',
                  isSelected: _isDaily,
                  onTap: () => setState(() {
                    _isDaily = true;
                    _weekDayError = false;
                  }),
                ),
              ),
              Space.horizontal(8),
              Expanded(
                child: _FrequencyButton(
                  label: 'Weekly',
                  sublabel: 'Pick days',
                  isSelected: !_isDaily,
                  onTap: () => setState(() => _isDaily = false),
                ),
              ),
            ],
          ),
          if (!_isDaily) ...[Space.vertical(12), _buildWeekDayPicker()],
        ],
      ),
    );
  }

  Widget _buildWeekDayPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(7, (i) {
            final isSelected = _selectedWeekDays.contains(i);
            return GestureDetector(
              onTap: () => setState(() {
                isSelected
                    ? _selectedWeekDays.remove(i)
                    : _selectedWeekDays.add(i);
                _weekDayError = false;
              }),
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
                    _weekDayLabels[i],
                    style: AppTextStyles.normal.copyWith(
                      fontSize: 12,
                      color: isSelected ? kWhiteColor : kBlackColor,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (_weekDayError) ...[
          Space.vertical(6),
          const _ErrorLabel('Please select at least one day'),
        ],
      ],
    );
  }

  // ── Section: Date range ────────────────────────────────────────────────────

  Widget _buildDateRangeSection() {
    return _Section(
      label: 'DATE RANGE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Start',
                  date: _startDate,
                  onTap: () async {
                    final picked = await _pickDate(
                      title: 'Start Date',
                      initial: _startDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                        _dateRangeError = false;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'End (optional)',
                  date: _endDate,
                  hint: 'No end date',
                  onTap: () async {
                    final picked = await _pickDate(
                      title: 'End Date',
                      initial: _endDate ?? _startDate,
                      firstDate: _startDate,
                    );
                    if (picked != null) {
                      setState(() {
                        _endDate = picked;
                        _dateRangeError = false;
                      });
                    }
                  },
                  onClear: _endDate == null
                      ? null
                      : () => setState(() => _endDate = null),
                ),
              ),
            ],
          ),
          if (_dateRangeError) ...[
            const SizedBox(height: 6),
            const _ErrorLabel('End date must be on or after start date'),
          ],
        ],
      ),
    );
  }

  // ── Section: Reminder ──────────────────────────────────────────────────────

  Widget _buildReminderSection() {
    return _Section(
      label: 'REMINDER',
      child: CustomTextField(
        controller: _reminderController,
        hintText: 'Reminder time — optional',
        readOnly: true,
        onTap: _pickReminderTime,
        suffix: const Icon(
          Icons.access_time_rounded,
          color: kGreyColor,
          size: 20,
        ),
      ),
    );
  }

  // ── Pickers ────────────────────────────────────────────────────────────────

  Future<void> _pickReminderTime() async {
    final now = DateTime.now();
    DateTime tempPicked = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );

    final confirmed = await AppBottomSheet.show<bool>(
      backgroundColor: kContainerColor,
      context,
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

    if (confirmed == true && mounted) {
      setState(
        () =>
            _reminderController.text = DateFormat('h:mm a').format(tempPicked),
      );
    }
  }

  Future<DateTime?> _pickDate({
    required String title,
    required DateTime initial,
    required DateTime firstDate,
  }) async {
    final lastDate = DateTime.now().add(const Duration(days: 365 * 5));
    DateTime tempPicked = initial.isBefore(firstDate)
        ? firstDate
        : (initial.isAfter(lastDate) ? lastDate : initial);

    final confirmed = await AppBottomSheet.show<bool>(
      backgroundColor: kContainerColor,
      context,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets (mirrors Add/Edit Habit styling)
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  final Widget child;

  const _Section({required this.label, required this.child});

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
    const months = [
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
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
                fontSize: 12,
                color: kWhiteColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? _format(date!) : hint,
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: hasValue ? kWhiteColor : kSecondaryGreyColor,
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

class _FrequencyButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyButton({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kDarkGreenColor : kWhiteColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 14,
                color: isSelected ? kWhiteColor : kBlackColor,
              ),
            ),
            Text(
              sublabel,
              style: AppTextStyles.normal.copyWith(
                fontSize: 12,
                color: isSelected ? kWhiteColor : kPrimaryGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
