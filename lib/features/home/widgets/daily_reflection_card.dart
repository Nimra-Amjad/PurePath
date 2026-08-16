import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/bloc/daily_reflection_bloc.dart';
import 'package:purepath/features/home/models/daily_reflection.dart';
import 'package:purepath/features/home/widgets/daily_reflection_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Daily reflection card
//
// The home-screen entry point for a day's mood + note. Watches the
// [DailyReflectionBloc] for [date] and renders one of two states:
//
//   • empty    → a muted prompt inviting the user to log how the day felt
//   • filled   → the mood emoji + label and a note preview, tinted with the
//                mood's accent colour so the whole card reads at a glance
//
// Tapping anywhere opens [DailyReflectionSheet] to edit.
// ─────────────────────────────────────────────────────────────────────────────

class DailyReflectionCard extends StatelessWidget {
  final DateTime date;

  const DailyReflectionCard({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailyReflectionBloc, DailyReflectionState>(
      builder: (context, state) {
        final reflection = state.reflectionFor(date) ?? const DailyReflection();
        final accent = reflection.mood?.color ?? kPrimaryGreenColor;

        return GestureDetector(
          onTap: () => DailyReflectionSheet.show(
            context,
            date: date,
            initial: reflection,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kContainerColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: reflection.isEmpty
                ? _EmptyReflection(accent: accent)
                : _FilledReflection(reflection: reflection, accent: accent),
          ),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyReflection extends StatelessWidget {
  final Color accent;

  const _EmptyReflection({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBubble(
          accent: accent,
          child: Icon(Icons.edit_note_rounded, color: accent, size: 24),
        ),
        Space.horizontal(14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How are you feeling?',
                style: AppTextStyles.semiBold.copyWith(
                  fontSize: 15,
                  color: kWhiteColor,
                ),
              ),
              Space.vertical(2),
              Text(
                'Log your mood & a note for this day',
                style: AppTextStyles.normal.copyWith(
                  fontSize: 12,
                  color: kLightGreyColor,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.add_rounded, color: accent, size: 22),
      ],
    );
  }
}

// ── Filled state ──────────────────────────────────────────────────────────────

class _FilledReflection extends StatelessWidget {
  final DailyReflection reflection;
  final Color accent;

  const _FilledReflection({required this.reflection, required this.accent});

  @override
  Widget build(BuildContext context) {
    final mood = reflection.mood;
    final note = reflection.note.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (mood != null) ...[
              _IconBubble(
                accent: accent,
                child: Text(mood.emoji, style: const TextStyle(fontSize: 22)),
              ),
              Space.horizontal(14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mood?.label ?? 'Note',
                    style: AppTextStyles.semiBold.copyWith(
                      fontSize: 15,
                      color: mood != null ? accent : kWhiteColor,
                    ),
                  ),
                  Space.vertical(2),
                  Text(
                    "Today's reflection",
                    style: AppTextStyles.normal.copyWith(
                      fontSize: 12,
                      color: kLightGreyColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_rounded, color: kLightGreyColor, size: 18),
          ],
        ),
        if (note.isNotEmpty) ...[
          Space.vertical(14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kContainerColorContrast,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              note,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.normal.copyWith(
                fontSize: 13,
                color: kWhiteColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Shared leading bubble ─────────────────────────────────────────────────────

class _IconBubble extends StatelessWidget {
  final Color accent;
  final Widget child;

  const _IconBubble({required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
