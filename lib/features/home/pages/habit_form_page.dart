import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/widgets/custom_back_button.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/features/home/bloc/home_bloc.dart';
import 'package:purepath/features/home/bloc/manage_habits_bloc.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/core/repositories/home_repository.dart';
import 'package:purepath/features/home/widgets/habit_form_fields.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/notifications/bloc/notification_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit Form Page
//
// One screen for both creating and editing a habit. Pass [habit] to edit an
// existing one; pass null to create a new one. The two modes share the exact
// same layout, fields, validation, and save flow — the only differences are the
// title, whether fields start pre-filled, and whether it adds or updates.
//
// Fields (all shared via habit_form_fields.dart):
//   Name → Task days → Reminder (optional) → Habit term
// ─────────────────────────────────────────────────────────────────────────────

class HabitFormPage extends StatefulWidget {
  /// The habit to edit, or null to create a new habit.
  final HabitDefinition? habit;

  const HabitFormPage({super.key, this.habit});

  bool get isEditing => habit != null;

  @override
  State<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends State<HabitFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _reminderController;

  late HabitSchedule _schedule;
  late final Set<int> _selectedWeekDays; // 0 = Mon … 6 = Sun
  late final Set<int> _selectedMonthDays; // 1 … 31
  late bool _reminderEnabled;
  late DateTime _startDate;
  DateTime? _endDate;
  late int _selectedColor;

  bool _weekDayError = false;
  bool _monthDayError = false;
  bool _reminderError = false;
  bool _dateRangeError = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameController = TextEditingController(text: h?.title ?? '');
    _reminderController = TextEditingController(text: h?.reminderTime ?? '');
    _schedule = h?.schedule ?? HabitSchedule.everyDay;
    _selectedWeekDays = Set.from(h?.weekDays ?? const <int>[]);
    _selectedMonthDays = Set.from(h?.monthDays ?? const <int>[]);
    _reminderEnabled = h?.reminderEnabled ?? false;
    _startDate = h?.startDate ?? _today();
    _endDate = h?.endDate;
    // Default to the palette's first entry (the shared default accent) so a new
    // habit always has a color even if the user never opens the picker.
    _selectedColor = h?.colorValue ?? kHabitColorPalette.first.toARGB32();
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  // ── Submit & validation ────────────────────────────────────────────────────

  Future<void> _onSaveTapped() async {
    if (_isSubmitting) return;

    setState(() {
      _weekDayError =
          _schedule == HabitSchedule.weekDays && _selectedWeekDays.isEmpty;
      _monthDayError =
          _schedule == HabitSchedule.monthDays && _selectedMonthDays.isEmpty;
      _reminderError =
          _reminderEnabled && _reminderController.text.trim().isEmpty;
      _dateRangeError = _endDate != null && _endDate!.isBefore(_startDate);
    });

    final formValid = _formKey.currentState!.validate();
    final selectionsValid = !_weekDayError &&
        !_monthDayError &&
        !_reminderError &&
        !_dateRangeError;

    if (!formValid || !selectionsValid) return;

    final weekDays = _schedule == HabitSchedule.weekDays
        ? (_selectedWeekDays.toList()..sort())
        : const <int>[];
    final monthDays = _schedule == HabitSchedule.monthDays
        ? (_selectedMonthDays.toList()..sort())
        : const <int>[];
    final reminderTime =
        _reminderEnabled ? _reminderController.text.trim() : '';

    setState(() => _isSubmitting = true);

    try {
      final repo = context.read<HomeRepository>();
      if (widget.isEditing) {
        final updated = widget.habit!.copyWith(
          title: _nameController.text.trim(),
          schedule: _schedule,
          weekDays: weekDays,
          monthDays: monthDays,
          reminderEnabled: _reminderEnabled,
          reminderTime: reminderTime,
          startDate: _startDate,
          endDate: _endDate,
          clearEndDate: _endDate == null,
          colorValue: _selectedColor,
        );
        await repo.updateHabit(updated);
      } else {
        final created = HabitDefinition(
          // id is ignored by the repository; Firestore generates a unique one.
          id: '',
          title: _nameController.text.trim(),
          type: HabitType.custom,
          schedule: _schedule,
          weekDays: weekDays,
          monthDays: monthDays,
          reminderEnabled: _reminderEnabled,
          reminderTime: reminderTime,
          startDate: _startDate,
          endDate: _endDate,
          colorValue: _selectedColor,
        );
        await repo.addHabit(created);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackBar.error(
        context,
        widget.isEditing
            ? 'Could not update habit. Please try again.'
            : 'Could not create habit. Please try again.',
      );
      return;
    }

    if (!mounted) return;

    // Refresh every screen that shows habits so the change lands immediately.
    context.read<HomeBloc>().add(HomeStarted());
    context.read<ManageHabitsBloc>().add(ManageHabitsStarted());
    context.read<InsightsBloc>().add(InsightsRefreshRequested());
    context.read<NotificationBloc>().add(const HabitNotificationsSynced());

    AppSnackBar.success(
      context,
      widget.isEditing
          ? 'Habit updated successfully!'
          : 'Habit created successfully!',
    );
    context.pop();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: AppBar(
        backgroundColor: kScaffoldColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: CustomBackButton(onTap: () => context.pop()),
        title: Text(
          widget.isEditing ? 'Edit Habit' : 'New Habit',
          style: AppTextStyles.bold.copyWith(fontSize: 20, color: kWhiteColor),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: PrimaryButton(
            text: 'Save',
            isLoading: _isSubmitting,
            onPressed: _onSaveTapped,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HabitNameField(controller: _nameController),
              const SizedBox(height: 24),
              HabitColorSection(
                selectedColor: _selectedColor,
                onColorSelected: (c) => setState(() => _selectedColor = c),
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
            ],
          ),
        ),
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
      // Permissive window so an already-started habit's date shows when editing.
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
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
