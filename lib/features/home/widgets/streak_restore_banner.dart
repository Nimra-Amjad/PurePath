import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';

/// Home-screen banner shown when the user's streak just broke and can be
/// repaired. Restoring is a Pro action — the parent decides whether tapping
/// [onRestore] runs the restore or opens the paywall.
class StreakRestoreBanner extends StatelessWidget {
  const StreakRestoreBanner({
    super.key,
    required this.recoveredStreak,
    required this.onRestore,
    this.isBusy = false,
  });

  /// Streak length the user gets back if they restore.
  final int recoveredStreak;
  final VoidCallback onRestore;

  /// True while a restore is in flight — disables the button + shows a spinner.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kOrangeColor.withOpacityValue(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOrangeColor.withOpacityValue(0.4)),
      ),
      child: Row(
        children: [
          Text('💔', style: AppTextStyles.bold.copyWith(fontSize: 30)),
          Space.horizontal(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You broke your streak!',
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 14,
                    color: kWhiteColor,
                  ),
                ),
                Space.vertical(2),
                Text(
                  'Restore it with Pro to get back to a '
                  '$recoveredStreak-day streak.',
                  style: AppTextStyles.normal.copyWith(
                    fontSize: 12,
                    color: kLightGreyColor,
                  ),
                ),
              ],
            ),
          ),
          Space.horizontal(12),
          GestureDetector(
            onTap: isBusy ? null : onRestore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: kOrangeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: isBusy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kBlackColor,
                      ),
                    )
                  : Text(
                      'Restore',
                      style: AppTextStyles.bold.copyWith(
                        fontSize: 13,
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
