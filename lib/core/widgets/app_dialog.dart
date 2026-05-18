import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppDialog
//
// Reusable custom dialog — replaces the generic Material AlertDialog.
// Appears with a smooth scale + fade animation.
//
// ── Quick usage ──────────────────────────────────────────────────────────────
//
//   final confirmed = await AppDialog.show(
//     context,
//     icon: Icons.logout_rounded,
//     iconColor: red,
//     title: 'Sign out?',
//     subtitle: "You'll need to log back in to access your account.",
//     confirmText: 'Sign out',
//     confirmColor: red,
//   );
//   if (confirmed == true) { ... }
//
// ─────────────────────────────────────────────────────────────────────────────

class AppDialog extends StatelessWidget {
  const AppDialog._({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.confirmText,
    required this.confirmColor,
    this.cancelText = 'Cancel',
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String confirmText;
  final Color confirmColor;
  final String cancelText;

  // ── Static helper ──────────────────────────────────────────────────────────

  /// Shows the dialog and returns `true` if the user confirmed, `false` / null
  /// if they dismissed or cancelled.
  static Future<bool?> show(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String confirmText,
    required Color confirmColor,
    String cancelText = 'Cancel',
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'dialog',
      barrierColor: kBlackColor.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => AppDialog._(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        confirmText: confirmText,
        confirmColor: confirmColor,
        cancelText: cancelText,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: kContainerColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: kBlackColor.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon badge ───────────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 18),

              // ── Title ────────────────────────────────────────────────────
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bold.copyWith(
                  fontSize: 18,
                  color: kWhiteColor,
                ),
              ),
              const SizedBox(height: 8),

              // ── Subtitle ─────────────────────────────────────────────────
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.normal.copyWith(
                  fontSize: 13.5,
                  color: kSecondaryGreyColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // ── Confirm button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: kWhiteColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    confirmText,
                    style: AppTextStyles.semiBold.copyWith(
                      fontSize: 15,
                      color: kWhiteColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Cancel button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    backgroundColor: kLightGreyColor.withValues(alpha: 0.6),
                    foregroundColor: textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    cancelText,
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 15,
                      color: textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
