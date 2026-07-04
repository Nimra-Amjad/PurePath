import 'package:flutter/foundation.dart';
import 'package:purepath/core/models/app_version_config.dart';
import 'package:purepath/core/providers/app_version_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppVersionRepository
//
// Business-logic layer over AppVersionProvider. The splash screen uses it to
// decide whether the installed build is outdated.
// ─────────────────────────────────────────────────────────────────────────────

class AppVersionRepository {
  final AppVersionProvider _provider;

  AppVersionRepository({required AppVersionProvider provider})
      : _provider = provider;

  /// Fetches the version config document. Returns null when the collection is
  /// empty or the fetch fails, in which case the app proceeds without an
  /// update prompt — a config hiccup must never lock users out.
  Future<AppVersionConfig?> fetchConfig() async {
    try {
      final data = await _provider.fetchConfigDoc();
      if (data == null) return null;
      return AppVersionConfig.fromMap(data);
    } catch (e) {
      debugPrint('AppVersionRepository.fetchConfig error: $e');
      return null;
    }
  }
}
