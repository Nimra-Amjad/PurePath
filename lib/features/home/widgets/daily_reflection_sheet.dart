import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/bloc/daily_reflection_bloc.dart';
import 'package:purepath/features/home/models/daily_reflection.dart';
import 'package:purepath/features/home/models/mood.dart';
import 'package:purepath/features/home/widgets/mood_selector.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Daily reflection sheet
//
// The editor for a single day's mood + note. Opened from [DailyReflectionCard].
// Holds the in-progress mood/note locally and only commits on Save, so backing
// out of the sheet discards edits. Saving dispatches [ReflectionSaved] on the
// [DailyReflectionBloc] read from the opening context.
// ─────────────────────────────────────────────────────────────────────────────

class DailyReflectionSheet extends StatefulWidget {
  final DateTime date;
  final DailyReflection initial;

  const DailyReflectionSheet({
    super.key,
    required this.date,
    required this.initial,
  });

  /// Opens the reflection editor for [date], pre-filled with [initial].
  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    required DailyReflection initial,
  }) {
    // The bloc lives above this context; capture it so the sheet (built by the
    // root navigator, outside this subtree) can still reach it.
    final bloc = context.read<DailyReflectionBloc>();
    return AppBottomSheet.show(
      context,
      body: BlocProvider.value(
        value: bloc,
        child: DailyReflectionSheet(date: date, initial: initial),
      ),
    );
  }

  @override
  State<DailyReflectionSheet> createState() => _DailyReflectionSheetState();
}

class _DailyReflectionSheetState extends State<DailyReflectionSheet> {
  late Mood? _mood = widget.initial.mood;
  late final TextEditingController _noteController =
      TextEditingController(text: widget.initial.note);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    context.read<DailyReflectionBloc>().add(
      ReflectionSaved(
        date: widget.date,
        reflection: DailyReflection(
          mood: _mood,
          note: _noteController.text.trim(),
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Daily Reflection',
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 18,
              color: kWhiteColor,
            ),
          ),
          Space.vertical(4),
          Text(
            DateFormat('EEEE, MMM d').format(widget.date),
            style: AppTextStyles.normal.copyWith(
              fontSize: 13,
              color: kLightGreyColor,
            ),
          ),
          Space.vertical(24),

          // ── Mood ──────────────────────────────────────────────────────────
          Text(
            'HOW DID THE DAY FEEL?',
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 12,
              color: kLightGreyColor,
              letterSpacing: 1.2,
            ),
          ),
          Space.vertical(14),
          MoodSelector(
            selected: _mood,
            onChanged: (mood) => setState(() => _mood = mood),
          ),
          Space.vertical(24),

          // ── Note ──────────────────────────────────────────────────────────
          Text(
            'NOTES',
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 12,
              color: kLightGreyColor,
              letterSpacing: 1.2,
            ),
          ),
          Space.vertical(10),
          TextField(
            controller: _noteController,
            maxLines: 5,
            minLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.normal.copyWith(
              fontSize: 14,
              color: kWhiteColor,
            ),
            cursorColor: kPrimaryGreenColor,
            decoration: InputDecoration(
              hintText: 'What happened today? What are you grateful for?',
              hintStyle: AppTextStyles.normal.copyWith(
                fontSize: 13,
                color: kSecondaryGreyColor,
              ),
              counterStyle: AppTextStyles.normal.copyWith(
                fontSize: 11,
                color: kSecondaryGreyColor,
              ),
              filled: true,
              fillColor: kContainerColor,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kPrimaryGreenColor),
              ),
            ),
          ),
          Space.vertical(16),

          // ── Save ──────────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreenColor,
                foregroundColor: kBlackColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Save Reflection',
                style: AppTextStyles.semiBold.copyWith(
                  fontSize: 15,
                  color: kBlackColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
