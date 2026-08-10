// Font Family Constants
const String kPrimaryFontFamily = 'Inter';

// App Version Constants
//
// Bump [kBuildNo] together with the build number in pubspec.yaml (the part
// after the `+`). The splash screen compares it against the `buildNo` stored
// in the Firestore `appVersionConfig` collection to decide whether to show
// the update sheet.
const int kBuildNo = 3;

// Store listing URLs opened by the update sheet.
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=ai.purepath';
// TODO: Replace with the real App Store link once the iOS app is published.
const String kAppStoreUrl = 'https://apps.apple.com/app/purepath';

// RevenueCat (in-app purchases)
//
// Public Android SDK key (safe to ship — it is not the secret key).
const String kRevenueCatAndroidApiKey = 'goog_ViDtpgaqAllXuprTowxAPvFScTo';

// Entitlement identifier configured in the RevenueCat dashboard. A user whose
// CustomerInfo has this entitlement active is a Pro subscriber.
const String kProEntitlementId = 'Pro';

// Free plan limit: adding a habit beyond this opens the paywall instead.
const int kFreeHabitLimit = 3;

// Debug-only Pro override for local testing (flutter run). Ignored entirely in
// release/Play builds, so it can never affect real users.
//   null  → use the real RevenueCat status
//   false → force FREE  (test the 3-habit limit + paywall)
//   true  → force PRO   (test unlocked features without buying)
const bool? kDebugForceProOverride = null;

// Legal
const String kPrivacyPolicyUrl =
    'https://www.freeprivacypolicy.com/live/9b400db2-ba32-48ad-bf46-8c563962b75c';

// Support
const String kSupportEmail = 'softsync77@gmail.com';
