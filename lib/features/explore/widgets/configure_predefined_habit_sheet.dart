import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/home/widgets/habit_form_fields.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Configure Predefined Habit Sheet
//
// Shown when the user taps a habit in the Habit Library. The title comes from
// the library entry and can't be changed — only the schedule and reminder are
// configurable here, using the same shared fields as the Add/Edit screens:
//
//   Task days → Reminder (optional) → Habit term
//
// On "Add Habit" the sheet pops with a fully-built [HabitDefinition] tagged as
// [HabitType.predefined]. The caller is responsible for persisting it.
// ─────────────────────────────────────────────────────────────────────────────

class ConfigurePredefinedHabitSheet extends StatefulWidget {
  const ConfigurePredefinedHabitSheet({super.key, required this.title});

  final String title;

  /// Opens the sheet and resolves to a configured [HabitDefinition], or null if
  /// the user dismissed it without confirming.
  static Future<HabitDefinition?> show(
    BuildContext context, {
    required String title,
  }) {
    return AppBottomSheet.show<HabitDefinition>(
      context,
      backgroundColor: kScaffoldColor,
      body: ConfigurePredefinedHabitSheet(title: title),
    );
  }

  @override
  State<ConfigurePredefinedHabitSheet> createState() =>
      _ConfigurePredefinedHabitSheetState();
}

class _ConfigurePredefinedHabitSheetState
    extends State<ConfigurePredefinedHabitSheet> {
  final _reminderController = TextEditingController();

  HabitSchedule _schedule = HabitSchedule.everyDay;
  final Set<int> _selectedWeekDays = {}; // 0 = Mon … 6 = Sun
  final Set<int> _selectedMonthDays = {}; // 1 … 31
  bool _reminderEnabled = false;

  late DateTime _startDate = _today();
  DateTime? _endDate;

  bool _weekDayError = false;
  bool _monthDayError = false;
  bool _reminderError = false;
  bool _dateRangeError = false;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _reminderController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    setState(() {
      _weekDayError =
          _schedule == HabitSchedule.weekDays && _selectedWeekDays.isEmpty;
      _monthDayError =
          _schedule == HabitSchedule.monthDays && _selectedMonthDays.isEmpty;
      _reminderError =
          _reminderEnabled && _reminderController.text.trim().isEmpty;
      _dateRangeError = _endDate != null && _endDate!.isBefore(_startDate);
    });

    if (_weekDayError || _monthDayError || _reminderError || _dateRangeError) {
      return;
    }

    final definition = HabitDefinition(
      id: '', // Firestore assigns a unique id.
      title: widget.title,
      type: HabitType.predefined,
      schedule: _schedule,
      weekDays: _schedule == HabitSchedule.weekDays
          ? (_selectedWeekDays.toList()..sort())
          : const [],
      monthDays: _schedule == HabitSchedule.monthDays
          ? (_selectedMonthDays.toList()..sort())
          : const [],
      reminderEnabled: _reminderEnabled,
      reminderTime: _reminderEnabled ? _reminderController.text.trim() : '',
      startDate: _startDate,
      endDate: _endDate,
    );

    context.pop(definition);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: habit being added ──────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: kHabitAccentColor.withValues(alpha: 0.2),
                child: const Text(kHabitEmoji, style: TextStyle(fontSize: 17)),
              ),
              Space.horizontal(12),
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 15,
                    color: kWhiteColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          TaskDaysSection(
            schedule: _schedule,
            selectedWeekDays: _selectedWeekDays,
            selectedMonthDays: _selectedMonthDays,
            weekDayError: _weekDayError,
            monthDayError: _monthDayError,
            onScheduleChanged: (s) => setState(() {
              _schedule = s;
              _weekDayError = false;
              _monthDayError = false;
            }),
            onWeekDayToggled: (i) => setState(() {
              _selectedWeekDays.contains(i)
                  ? _selectedWeekDays.remove(i)
                  : _selectedWeekDays.add(i);
              _weekDayError = false;
            }),
            onMonthDayToggled: (d) => setState(() {
              _selectedMonthDays.contains(d)
                  ? _selectedMonthDays.remove(d)
                  : _selectedMonthDays.add(d);
              _monthDayError = false;
            }),
          ),
          const SizedBox(height: 24),
          ReminderSection(
            enabled: _reminderEnabled,
            timeController: _reminderController,
            showError: _reminderError,
            onToggled: (on) => setState(() {
              _reminderEnabled = on;
              _reminderError = false;
              if (!on) _reminderController.clear();
            }),
            onPickTime: _pickReminderTime,
          ),
          const SizedBox(height: 24),
          HabitTermSection(
            startDate: _startDate,
            endDate: _endDate,
            showError: _dateRangeError,
            onPickStart: _pickStartDate,
            onPickEnd: _pickEndDate,
            onClearEnd: _endDate == null
                ? null
                : () => setState(() => _endDate = null),
          ),
          const SizedBox(height: 28),

          PrimaryButton(text: 'Add Habit', onPressed: _onConfirm),
        ],
      ),
    );
  }

  // ── Pickers ────────────────────────────────────────────────────────────────

  Future<void> _pickReminderTime() async {
    final picked = await showHabitTimePicker(context);
    if (picked != null && mounted) {
      setState(() {
        _reminderController.text = DateFormat('h:mm a').format(picked);
        _reminderError = false;
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showHabitDatePicker(
      context,
      title: 'Start Date',
      initial: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _dateRangeError = false;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showHabitDatePicker(
      context,
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
  }
}
