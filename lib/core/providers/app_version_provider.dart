import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppVersionProvider
//
// The only place that touches Firestore for the `appVersionConfig`
// collection. Returns raw document data — parsing into a model and error
// policy live in AppVersionRepository.
// ─────────────────────────────────────────────────────────────────────────────

class AppVersionProvider {
  static const _kAppVersionConfig = 'appVersionConfig';

  final FirebaseFirestore _firestore;

  AppVersionProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Raw data of the first config document, or null when the collection is
  /// empty.
  Future<Map<String, dynamic>?> fetchConfigDoc() async {
    final snap =
        await _firestore.collection(_kAppVersionConfig).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }
}
