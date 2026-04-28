import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/custom_textfield.dart';
import 'package:purepath/features/home/bloc/manage_habits_bloc.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/home/models/habit_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Edit Habit Page
//
// Pre-fills all form fields from an existing [HabitDefinition].
// The form structure mirrors AddHabitPage — same sections, same validations.
//
// On "Save Changes" tap:
//   • All fields are validated simultaneously
//   • On success → dispatches [ManageHabitUpdateRequested] to [ManageHabitsBloc]
//     and pops back to ManageHabitsPage
//
// Navigation: opened via Navigator.push with BlocProvider.value so it shares
// the same [ManageHabitsBloc] instance as its parent.
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
  late final TextEditingController _goalController;
  late final TextEditingController _reminderController;

  // ── Selections ────────────────────────────────────────────────────────────
  late HabitCategory? _selectedCategory;
  late bool _isDaily;
  late final Set<int> _selectedWeekDays;

  // ── Validation error flags ─────────────────────────────────────────────────
  bool _categoryError = false;
  bool _weekDayError = false;

  // ── Static data ────────────────────────────────────────────────────────────
  static const _allCategories = HabitCategory.values;
  static const _weekDayLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Pre-fill every field from the existing habit definition.
    final h = widget.habit;
    _nameController = TextEditingController(text: h.title);
    _goalController = TextEditingController(text: h.goal);
    _reminderController = TextEditingController(text: h.reminderTime);
    _selectedCategory = h.category;
    _isDaily = h.isDaily;
    _selectedWeekDays = Set.from(h.weekDays);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  void _onSaveTapped() {
    setState(() {
      _categoryError = _selectedCategory == null;
      _weekDayError = !_isDaily && _selectedWeekDays.isEmpty;
    });

    final formValid = _formKey.currentState!.validate();
    final selectionsValid = !_categoryError && !_weekDayError;

    if (!formValid || !selectionsValid) return;

    final updated = widget.habit.copyWith(
      title: _nameController.text.trim(),
      category: _selectedCategory,
      isDaily: _isDaily,
      weekDays: _isDaily ? [] : _selectedWeekDays.toList()..sort(),
      goal: _goalController.text.trim(),
      reminderTime: _reminderController.text.trim(),
    );

    context.read<ManageHabitsBloc>().add(ManageHabitUpdateRequested(updated));
    Navigator.of(context).pop();
  }

  // ── Time picker ────────────────────────────────────────────────────────────

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: purple),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _reminderController.text = picked.format(context));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameSection(),
              const SizedBox(height: 28),
              _buildCategorySection(),
              const SizedBox(height: 28),
              _buildFrequencySection(),
              const SizedBox(height: 28),
              _buildGoalReminderSection(),
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
      backgroundColor: kWhiteColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: kBlackColor,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Edit Habit',
        style: AppTextStyles.bold.copyWith(fontSize: 20),
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
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
            ),
            itemCount: _allCategories.length,
            itemBuilder: (_, i) {
              final category = _allCategories[i];
              final isSelected = _selectedCategory == category;
              final categoryColor = category.color;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCategory = category;
                  _categoryError = false;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? categoryColor.withValues(alpha: 0.12)
                        : kWhiteColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? categoryColor
                          : kGreyColor.withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            category.emoji,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          category.label,
                          style: AppTextStyles.medium.copyWith(
                            fontSize: 11,
                            color: isSelected ? categoryColor : kDarkGreyColor,
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
              const SizedBox(width: 12),
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
          if (!_isDaily) ...[const SizedBox(height: 14), _buildWeekDayPicker()],
        ],
      ),
    );
  }

  Widget _buildWeekDayPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
                  color: isSelected ? purple : kWhiteColor,
                  border: Border.all(
                    color: isSelected
                        ? purple
                        : kGreyColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    _weekDayLabels[i],
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 10,
                      color: isSelected ? kWhiteColor : kDarkGreyColor,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (_weekDayError) ...[
          const SizedBox(height: 6),
          const _ErrorLabel('Please select at least one day'),
        ],
      ],
    );
  }

  // ── Section: Goal & Reminder ───────────────────────────────────────────────

  Widget _buildGoalReminderSection() {
    return _Section(
      label: 'GOAL & REMINDER',
      child: Column(
        children: [
          CustomTextField(
            controller: _goalController,
            hintText: 'Goal (e.g. 5 km) — optional',
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(100)],
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return null;
              if (v.length < 3) return 'Goal description is too short';
              return null;
            },
          ),
          const SizedBox(height: 12),
          CustomTextField(
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
        ],
      ),
    );
  }

  // ── Save button ────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _onSaveTapped,
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: kWhiteColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
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
            color: kDarkGreyColor.withValues(alpha: 0.55),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? purple : kWhiteColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? purple : kGreyColor.withValues(alpha: 0.3),
          ),
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
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: AppTextStyles.normal.copyWith(
                fontSize: 12,
                color: isSelected
                    ? kWhiteColor.withValues(alpha: 0.75)
                    : kGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
