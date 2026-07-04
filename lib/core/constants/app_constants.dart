// Font Family Constants
const String kPrimaryFontFamily = 'Inter';

// App Version Constants
//
// Bump [kBuildNo] together with the build number in pubspec.yaml (the part
// after the `+`). The splash screen compares it against the `buildNo` stored
// in the Firestore `appVersionConfig` collection to decide whether to show
// the update sheet.
const int kBuildNo = 1;

// Store listing URLs opened by the update sheet.
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=ai.purepath';
// TODO: Replace with the real App Store link once the iOS app is published.
const String kAppStoreUrl = 'https://apps.apple.com/app/purepath';

// Legal
const String kPrivacyPolicyUrl =
    'https://www.freeprivacypolicy.com/live/9b400db2-ba32-48ad-bf46-8c563962b75c';
