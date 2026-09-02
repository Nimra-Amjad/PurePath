import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/custom_textfield.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/planner/models/planner_task.dart';
import 'package:purepath/features/planner/widgets/planner_hour_label.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Planner task sheet
//
// One bottom sheet for both adding and editing a task at a given hour slot.
// It's a "dumb" input surface: it collects a title + note and hands them back
// through [onSubmit]. The page owns the bloc dispatch, so this widget stays
// decoupled from PlannerBloc. In edit mode a delete affordance appears and
// fires [onDelete].
// ─────────────────────────────────────────────────────────────────────────────

class PlannerTaskSheet extends StatefulWidget {
  const PlannerTaskSheet({
    super.key,
    required this.hour,
    required this.onSubmit,
    this.existing,
    this.onDelete,
  });

  /// The slot the task belongs to (0–23). Shown in the header.
  final int hour;

  /// The task being edited, or null when adding a new one.
  final PlannerTask? existing;

  /// Fired with the trimmed title + note when the user taps Save.
  final void Function(String title, String note) onSubmit;

  /// Fired when the user deletes an existing task. Null hides the delete icon.
  final VoidCallback? onDelete;

  /// Opens the sheet for adding a new task at [hour].
  static Future<void> showAdd(
    BuildContext context, {
    required int hour,
    required void Function(String title, String note) onSubmit,
  }) {
    return AppBottomSheet.show(
      context,
      body: PlannerTaskSheet(hour: hour, onSubmit: onSubmit),
    );
  }

  /// Opens the sheet pre-filled with [task] for editing.
  static Future<void> showEdit(
    BuildContext context, {
    required PlannerTask task,
    required void Function(String title, String note) onSubmit,
    required VoidCallback onDelete,
  }) {
    return AppBottomSheet.show(
      context,
      body: PlannerTaskSheet(
        hour: task.hour,
        existing: task,
        onSubmit: onSubmit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<PlannerTaskSheet> createState() => _PlannerTaskSheetState();
}

class _PlannerTaskSheetState extends State<PlannerTaskSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _noteController = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return; // nothing to save
    widget.onSubmit(title, _noteController.text.trim());
    context.pop();
  }

  void _delete() {
    context.pop();
    widget.onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: time slot + optional delete ──────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kPrimaryGreenColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  plannerHourLabel(widget.hour),
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 14,
                    color: kPrimaryGreenColor,
                  ),
                ),
              ),
              Space.horizontal(12),
              Expanded(
                child: Text(
                  _isEditing ? 'Edit task' : 'New task',
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 18,
                    color: kWhiteColor,
                  ),
                ),
              ),
              if (widget.onDelete != null)
                GestureDetector(
                  onTap: _delete,
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: kRedColor,
                    size: 24,
                  ),
                ),
            ],
          ),
          Space.vertical(20),

          // ── Title ─────────────────────────────────────────────────────────
          CustomTextField(
            controller: _titleController,
            hintText: 'What do you want to do?',
            textCapitalization: TextCapitalization.sentences,
            onFieldSubmitted: (_) => _submit(),
          ),
          Space.vertical(12),

          // ── Note (optional) ───────────────────────────────────────────────
          CustomTextField(
            controller: _noteController,
            hintText: 'Add a note (optional)',
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            minLines: 2,
          ),
          Space.vertical(24),

          PrimaryButton(
            text: _isEditing ? 'Save changes' : 'Add task',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
