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
import 'package:purepath/core/repositories/home_repository.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/notifications/bloc/notification_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add Habit Page
//
// Lets the user create a new habit by filling in:
//   Name → Category → Frequency → Reminder (optional)
//
// Color and emoji are derived automatically from the chosen category —
// no separate icon picker or color picker is shown.
//
// On "Create Habit" tap:
//   • All fields are validated simultaneously
//   • Inline errors appear next to the relevant section
//   • On success → shows a snackbar (hook up your bloc/repository here)
//
// TO CONNECT LATER:
//   Replace the TODO comment in [_onCreateTapped] with a BLoC dispatch.
// ─────────────────────────────────────────────────────────────────────────────

class AddHabitPage extends StatefulWidget {
  const AddHabitPage({super.key});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _reminderController = TextEditingController();

  // ── Selections ────────────────────────────────────────────────────────────
  HabitCategory? _selectedCategory;
  bool _isDaily = true;
  final Set<int> _selectedWeekDays = {}; // 0 = Mon … 6 = Sun

  // Defaults: start = today, end = open-ended (null).
  late DateTime _startDate = _today();
  DateTime? _endDate;

  // ── Validation error flags (for non-FormField widgets) ────────────────────
  bool _categoryError = false;
  bool _weekDayError = false;
  bool _dateRangeError = false;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ── Submission state ───────────────────────────────────────────────────────
  bool _isSubmitting = false;

  // ── Static data ────────────────────────────────────────────────────────────

  /// All 15 categories in display order.
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
  void dispose() {
    _nameController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  // ── Submit & validation ────────────────────────────────────────────────────

  Future<void> _onCreateTapped() async {
    if (_isSubmitting) return;

    // Validate custom selections (not covered by FormField validators)
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

    final newHabit = HabitDefinition(
      // id is ignored by the repository; Firestore generates a unique one.
      id: '',
      title: _nameController.text.trim(),
      category: _selectedCategory!,
      // The user built this habit themselves.
      type: HabitType.custom,
      isDaily: _isDaily,
      weekDays: weekDays,
      reminderTime: _reminderController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
    );

    setState(() => _isSubmitting = true);

    try {
      await context.read<HomeRepository>().addHabit(newHabit);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackBar.error(context, 'Could not create habit. Please try again.');
      return;
    }

    if (!mounted) return;

    // Refresh home + manage + insights so the new habit shows up under
    // each day immediately on every screen.
    context.read<HomeBloc>().add(HomeStarted());
    context.read<ManageHabitsBloc>().add(ManageHabitsStarted());
    context.read<InsightsBloc>().add(InsightsRefreshRequested());

    // Re-sync OS reminders so the new habit's reminderTime is honored.
    context.read<NotificationBloc>().add(const HabitNotificationsSynced());

    AppSnackBar.success(context, 'Habit created successfully!');
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
              PrimaryButton(
                text: "Create Habit",
                isLoading: _isSubmitting,
                onPressed: () {
                  _onCreateTapped();
                },
              ),
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
        'New Habit',
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
        textCapitalization: TextCapitalization.words,
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
  //
  // Shows all 15 categories in a 3-column grid.
  // Each cell displays the category's emoji and label.
  // Selecting a category automatically determines color and emoji —
  // the user never needs to pick them separately.

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
                      // Emoji with tinted circular background
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: categoryColor.withValues(alpha: 0.2),
                        child: Text(
                          category.emoji,
                          style: AppTextStyles.medium.copyWith(fontSize: 15),
                        ),
                      ),
                      Space.horizontal(8),
                      // Category label
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
          // Day picker — only visible when Weekly is selected
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
  //
  // Start date defaults to today. End date is optional (open-ended habit).
  // The habit is only shown on dates inside [startDate, endDate].

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
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps a form section with a small uppercase label above its content.
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

/// Red error text shown under custom (non-FormField) selection widgets.
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

/// Tappable read-only field that opens a date picker.
/// Optionally renders a small clear button when [onClear] is provided.
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

/// Daily / Weekly toggle button used in the Frequency section.
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
