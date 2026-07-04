import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:purepath/core/models/app_version_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppVersionRepository
//
// The only place that talks to Firestore for app-version data. The splash
// screen uses it to decide whether the installed build is outdated.
// ─────────────────────────────────────────────────────────────────────────────

class AppVersionRepository {
  static const _kAppVersionConfig = 'appVersionConfig';

  /// Fetches the version config document. Returns null when the collection is
  /// empty or the fetch fails, in which case the app proceeds without an
  /// update prompt — a config hiccup must never lock users out.
  Future<AppVersionConfig?> fetchConfig() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_kAppVersionConfig)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      return AppVersionConfig.fromMap(snap.docs.first.data());
    } catch (e) {
      debugPrint('AppVersionRepository.fetchConfig error: $e');
      return null;
    }
  }
}
