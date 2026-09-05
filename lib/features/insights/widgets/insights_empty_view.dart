import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/paywall/utils/habit_limit_gate.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Insights empty view
//
// Shown on the Insights tab when the user has not created any habits yet.
// Instead of an empty bar chart, it welcomes the user, previews what insights
// they'll unlock, and offers a direct path to add their first habit.
// ─────────────────────────────────────────────────────────────────────────────

class InsightsEmptyView extends StatelessWidget {
  const InsightsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Space.vertical(32),

        // ── Hero icon ────────────────────────────────────────────────────────
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: purple.withOpacityValue(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: purple,
              size: 44,
            ),
          ),
        ),
        Space.vertical(20),

        // ── Heading + subtext ────────────────────────────────────────────────
        Center(
          child: Text(
            'Your insights start here',
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 20,
              color: kWhiteColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Space.vertical(8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Create your first habit and watch your weekly progress, '
              'coins, and collection come to life.',
              style: AppTextStyles.normal.copyWith(
                fontSize: 14,
                color: textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Space.vertical(24),

        // ── Feature preview list ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kContainerColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: const [
              _FeatureRow(
                icon: Icons.bar_chart_rounded,
                title: 'Weekly overview',
                subtitle: 'See how each day of the week is going.',
              ),
              _FeatureDivider(),
              _FeatureRow(
                icon: Icons.trending_up_rounded,
                title: 'Habit progress',
                subtitle: 'Track completion for every habit.',
              ),
              _FeatureDivider(),
              _FeatureRow(
                icon: Icons.grid_view_rounded,
                title: 'Habit collection',
                subtitle: 'Build a completion grid you can be proud of.',
              ),
            ],
          ),
        ),
        Space.vertical(28),

        // ── Call to action ───────────────────────────────────────────────────
        PrimaryButton(
          text: 'Add Your First Habit',
          onPressed: () => openAddHabitGated(context),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature row — one previewed insight capability.
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kPrimaryGreyColor.withOpacityValue(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kLightGreenColor, size: 20),
        ),
        Space.horizontal(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kWhiteColor,
                ),
              ),
              Space.vertical(2),
              Text(
                subtitle,
                style: AppTextStyles.normal.copyWith(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureDivider extends StatelessWidget {
  const _FeatureDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        thickness: 1,
        color: kPrimaryGreyColor.withOpacityValue(0.2),
      ),
    );
  }
}
