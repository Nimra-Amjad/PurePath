import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/features/home/models/mood.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mood selector
//
// The five moods rendered as a row of equal-width cards (emoji over label). The
// [selected] card lifts with a lime border, a soft green glow and a lime label;
// the rest stay muted. Tapping the already-selected mood clears it (passes
// null), so a mis-tap is easy to undo.
//
// Pure presentation — state lives in the parent (the reflection sheet).
// ─────────────────────────────────────────────────────────────────────────────

class MoodSelector extends StatelessWidget {
  final Mood? selected;
  final ValueChanged<Mood?> onChanged;

  const MoodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const moods = Mood.values;

    return Row(
      children: [
        for (var i = 0; i < moods.length; i++) ...[
          Expanded(
            child: _MoodOption(
              mood: moods[i],
              isSelected: moods[i] == selected,
              onTap: () =>
                  onChanged(moods[i] == selected ? null : moods[i]),
            ),
          ),
          if (i != moods.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _MoodOption extends StatelessWidget {
  final Mood mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodOption({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  // A single brand accent for the selected state, matching the app's green.
  static const Color _accent = kPrimaryGreenColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? _accent.withOpacityValue(0.08)
              : kContainerColorContrast,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? _accent
                : kWhiteColor.withOpacityValue(0.05),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _accent.withOpacityValue(0.30),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(
              mood.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.medium.copyWith(
                fontSize: 12.5,
                color: isSelected ? _accent : kLightGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
