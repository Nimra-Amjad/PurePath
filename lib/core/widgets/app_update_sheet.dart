import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_constants.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppUpdateSheet
//
// Shown after the splash delay when the build number in Firestore's
// `appVersionConfig` is higher than the installed [kBuildNo].
//
//   forceUpdate == true  → sheet cannot be dismissed (no drag, no outside tap,
//                          no back button) — the only way forward is the store.
//   forceUpdate == false → user may dismiss via the "Not Now" button, drag or
//                          outside tap, and continue into the app.
//
// [show] resolves when the sheet is dismissed, which for a forced update is
// never — callers must not await it before deciding to block navigation.
// ─────────────────────────────────────────────────────────────────────────────

class AppUpdateSheet extends StatelessWidget {
  const AppUpdateSheet({super.key, required this.forceUpdate});

  final bool forceUpdate;

  /// Opens the update sheet. Resolves when the user dismisses it (only
  /// possible when [forceUpdate] is false).
  static Future<void> show(BuildContext context, {required bool forceUpdate}) {
    return AppBottomSheet.show<void>(
      context,
      isDismissible: !forceUpdate,
      enableDrag: !forceUpdate,
      showSheetHandler: !forceUpdate,
      body: AppUpdateSheet(forceUpdate: forceUpdate),
    );
  }

  Future<void> _openStore() async {
    final url = defaultTargetPlatform == TargetPlatform.iOS
        ? kAppStoreUrl
        : kPlayStoreUrl;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    // Blocks the Android back button for forced updates.
    return PopScope(
      canPop: !forceUpdate,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.system_update_alt_rounded,
              size: 48,
              color: kPrimaryGreenColor,
            ),
            Space.vertical(16),
            Text(
              'Update Available',
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 20,
                color: kWhiteColor,
              ),
            ),
            Space.vertical(8),
            Text(
              forceUpdate
                  ? 'This version of PurePath is no longer supported. '
                        'Please update to continue.'
                  : 'A new version of PurePath is available with the latest '
                        'improvements and fixes.',
              textAlign: TextAlign.center,
              style: AppTextStyles.normal.copyWith(
                fontSize: 14,
                color: kGreyColor,
              ),
            ),
            Space.vertical(24),
            PrimaryButton(text: 'Update Now', onPressed: _openStore),
            if (!forceUpdate) ...[
              Space.vertical(12),
              PrimaryButton(
                text: 'Not Now',
                buttonColor: kTransparentColor,
                textColor: kWhiteColor,
                showBorder: true,
                borderColor: kGreyColor,
                onPressed: () => AppBottomSheet.hide(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
