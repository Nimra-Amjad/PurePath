import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/custom_back_button.dart';
import 'package:purepath/core/widgets/custom_textfield.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/bloc/home_bloc.dart';
import 'package:purepath/features/home/bloc/manage_habits_bloc.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/home/models/habit_model.dart';
import 'package:purepath/features/home/repositories/home_repository.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/notifications/bloc/notification_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Edit Habit Page
//
// Pre-fills all form fields from an existing [HabitDefinition].
// The form structure mirrors AddHabitPage — same sections, same validations,
// same dark theme.
//
// On "Save Changes" tap:
//   • All fields are validated simultaneously
//   • On success → persists via HomeRepository, refreshes the dependent
//     blocs, then pops back to ManageHabitsPage.
// ─────────────────────────────────────────────────────────────────────────────

class EditHabitPage extends StatefulWidget {
  final HabitDefinition habit;

  const EditHabitPage({super.key, required this.habit});

  @override
  State<EditHabitPage> createState() => _EditHabitPageState();
}

class _EditHabitPageState extends State<EditHabitPage> {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _reminderController;

  // ── Selections ────────────────────────────────────────────────────────────
  late HabitCategory? _selectedCategory;
  late bool _isDaily;
  late final Set<int> _selectedWeekDays;
  late DateTime _startDate;
  DateTime? _endDate;

  // ── Validation error flags (for non-FormField widgets) ────────────────────
  bool _categoryError = false;
  bool _weekDayError = false;
  bool _dateRangeError = false;

  // ── Submission state ───────────────────────────────────────────────────────
  bool _isSubmitting = false;

  // ── Static data ────────────────────────────────────────────────────────────

  static const _allCategories = HabitCategory.values;

  static const _weekDayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Pre-fill every field from the existing habit definition.
    final h = widget.habit;
    _nameController = TextEditingController(text: h.title);
    _reminderController = TextEditingController(text: h.reminderTime);
    _selectedCategory = h.category;
    _isDaily = h.isDaily;
    _selectedWeekDays = Set.from(h.weekDays);
    _startDate = h.startDate;
    _endDate = h.endDate;
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
      _categoryError = _selectedCategory == null;
      _weekDayError = !_isDaily && _selectedWeekDays.isEmpty;
      _dateRangeError = _endDate != null && _endDate!.isBefore(_startDate);
    });

    final formValid = _formKey.currentState!.validate();
    final selectionsValid =
        !_categoryError && !_weekDayError && !_dateRangeError;

    if (!formValid || !selectionsValid) return;

    final weekDays = _isDaily
        ? const <int>[]
        : (_selectedWeekDays.toList()..sort());

    final updated = widget.habit.copyWith(
      title: _nameController.text.trim(),
      category: _selectedCategory,
      isDaily: _isDaily,
      weekDays: weekDays,
      reminderTime: _reminderController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      clearEndDate: _endDate == null,
    );

    setState(() => _isSubmitting = true);

    try {
      await context.read<HomeRepository>().updateHabit(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackBar.error(context, 'Could not update habit. Please try again.');
      return;
    }

    if (!mounted) return;

    // Push the updated definition into every screen that displays it.
    context.read<ManageHabitsBloc>().add(ManageHabitsStarted());
    context.read<HomeBloc>().add(HomeStarted());
    context.read<InsightsBloc>().add(InsightsRefreshRequested());

    // Re-sync OS reminders so the edited reminderTime is honored.
    context.read<NotificationBloc>().add(const HabitNotificationsSynced());

    AppSnackBar.success(context, 'Habit updated successfully!');
    context.pop();
  }

  // ── Time picker ────────────────────────────────────────────────────────────

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
            PrimaryButton(
              text: "Add Time",
              onPressed: () => context.pop(true),
            ),
            Space.vertical(32),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(
        () => _reminderController.text = DateFormat('h:mm a').format(tempPicked),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameSection(),
              const SizedBox(height: 24),
              _buildCategorySection(),
              const SizedBox(height: 8),
              _buildFrequencySection(),
              const SizedBox(height: 24),
              _buildDateRangeSection(),
              const SizedBox(height: 24),
              _buildReminderSection(),
              const SizedBox(height: 36),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: kScaffoldColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: CustomBackButton(
        onTap: () {
          context.pop();
        },
      ),
      title: Text(
        'Edit Habit',
        style: AppTextStyles.bold.copyWith(fontSize: 20, color: kWhiteColor),
      ),
    );
  }

  // ── Section: Habit name ────────────────────────────────────────────────────

  Widget _buildNameSection() {
    return _Section(
      label: 'HABIT NAME',
      child: CustomTextField(
        controller: _nameController,
        hintText: 'e.g. Morning Run',
        textCapitalization: TextCapitalization.sentences,
        inputFormatters: [LengthLimitingTextInputFormatter(50)],
        validator: (value) {
          final v = value?.trim() ?? '';
          if (v.isEmpty) return 'Please enter a habit name';
          if (v.length < 2) return 'Name must be at least 2 characters';
          return null;
        },
      ),
    );
  }

  // ── Section: Category ──────────────────────────────────────────────────────

  Widget _buildCategorySection() {
    return _Section(
      label: 'CATEGORY',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 2,
            ),
            itemCount: _allCategories.length,
            itemBuilder: (_, i) {
              final category = _allCategories[i];
              final isSelected = _selectedCategory == category;
              final categoryColor = category.color;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    _categoryError = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? categoryColor.withValues(alpha: 0.12)
                        : kContainerColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? categoryColor
                          : kSecondaryGreyColor.withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: categoryColor.withValues(alpha: 0.2),
                        child: Text(
                          category.emoji,
                          style: AppTextStyles.medium.copyWith(fontSize: 15),
                        ),
                      ),
                      Space.horizontal(8),
                      Expanded(
                        child: Text(
                          category.label,
                          style: AppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: isSelected ? categoryColor : kWhiteColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_categoryError) ...[
            const SizedBox(height: 6),
            const _ErrorLabel('Please select a category'),
          ],
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
                        const Duration(days: 365 * 5),
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
            PrimaryButton(
              text: "Set Date",
              onPressed: () => context.pop(true),
            ),
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

  // ── Save button ────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _onSaveTapped,
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: kWhiteColor,
          disabledBackgroundColor: purple.withValues(alpha: 0.6),
          disabledForegroundColor: kWhiteColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: kWhiteColor,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Save Changes',
                    style: AppTextStyles.semiBold.copyWith(
                      fontSize: 16,
                      color: kWhiteColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_rounded, size: 20),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets (mirrors AddHabitPage exactly)
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
