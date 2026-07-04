// ─────────────────────────────────────────────────────────────────────────────
// AppVersionConfig
//
// Mirrors a document in the Firestore `appVersionConfig` collection:
//
//   buildNo:     latest published build number
//   forceUpdate: when true the update sheet cannot be dismissed
//
// The console stores these as strings ("1", "true"), so parsing accepts both
// string and native types.
// ─────────────────────────────────────────────────────────────────────────────

class AppVersionConfig {
  const AppVersionConfig({required this.buildNo, required this.forceUpdate});

  final int buildNo;
  final bool forceUpdate;

  factory AppVersionConfig.fromMap(Map<String, dynamic> map) {
    return AppVersionConfig(
      buildNo: _parseInt(map['buildNo']),
      forceUpdate: _parseBool(map['forceUpdate']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
}
