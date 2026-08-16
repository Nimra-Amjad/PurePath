import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/features/home/models/mood.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mood selector
//
// A row of the five moods rendered as tappable emoji pills. The [selected]
// mood fills with its own accent colour; the rest stay muted. Tapping the
// already-selected mood clears it (passes null), so a mis-tap is easy to undo.
//
// Pure presentation — state lives in the parent (the reflection sheet).
// ─────────────────────────────────────────────────────────────────────────────

class MoodSelector extends StatelessWidget {
  final Mood? selected;
  final ValueChanged<Mood?> onChanged;

  const MoodSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final mood in Mood.values)
          _MoodOption(
            mood: mood,
            isSelected: mood == selected,
            onTap: () => onChanged(mood == selected ? null : mood),
          ),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? mood.color.withValues(alpha: 0.18)
                  : kContainerColorContrast,
              border: Border.all(
                color: isSelected ? mood.color : kTransparentColor,
                width: 2,
              ),
            ),
            child: Text(mood.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 6),
          Text(
            mood.label,
            style: AppTextStyles.medium.copyWith(
              fontSize: 11,
              color: isSelected ? mood.color : kLightGreyColor,
            ),
          ),
        ],
      ),
    );
  }
}
