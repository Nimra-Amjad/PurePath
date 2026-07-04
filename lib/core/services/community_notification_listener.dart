import 'dart:async';

import 'package:purepath/core/repositories/community_repository.dart';
import 'package:purepath/core/repositories/user_repository.dart';
import 'package:purepath/core/services/notification_service.dart';
import 'package:purepath/features/community/models/community_notification.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CommunityNotificationListener
//
// Bridges Firestore community notifications to device notifications while
// the app is alive:
//
//   users/<uid>/notifications  ──stream──►  system notification banner
//
// Lifecycle: started once from DI (lazy: false) and follows the auth state —
// it subscribes when a user is available and tears down on logout.
//
// The first snapshot after subscribing only seeds the "already seen" set, so
// the existing backlog never replays as banners; only notifications that
// arrive while the app is running are shown.
//
// NOTE: this is client-side only — it cannot fire when the app is fully
// killed. True push in that case needs FCM + a Cloud Function trigger.
// ─────────────────────────────────────────────────────────────────────────────

class CommunityNotificationListener {
  final CommunityRepository communityRepository;
  final UserRepository userRepository;
  final NotificationService notificationService;

  CommunityNotificationListener({
    required this.communityRepository,
    required this.userRepository,
    required this.notificationService,
  });

  StreamSubscription? _userSub;
  StreamSubscription<List<CommunityNotification>>? _notificationsSub;

  String? _currentUid;
  final Set<String> _seenIds = {};
  bool _seeded = false;

  /// Begins following the auth state. Safe to call once at app start.
  void start() {
    _subscribeFor(userRepository.localUser?.uid);
    _userSub = userRepository.userModelStream.listen(
      (user) => _subscribeFor(user?.uid),
    );
  }

  void dispose() {
    _userSub?.cancel();
    _notificationsSub?.cancel();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _subscribeFor(String? uid) {
    if (uid == _currentUid) return;
    _currentUid = uid;

    _notificationsSub?.cancel();
    _notificationsSub = null;
    _seenIds.clear();
    _seeded = false;

    if (uid == null || uid.isEmpty) return;

    _notificationsSub =
        communityRepository.watchNotifications(uid).listen(_onNotifications);
  }

  void _onNotifications(List<CommunityNotification> notifications) {
    if (!_seeded) {
      // First snapshot = existing history. Remember it, don't announce it.
      _seenIds.addAll(notifications.map((n) => n.id));
      _seeded = true;
      return;
    }

    for (final n in notifications) {
      if (!_seenIds.add(n.id)) continue; // already known
      if (n.hasRead) continue;

      notificationService.showCommunityNotification(
        // Stable per event → re-emissions can't duplicate the banner.
        id: n.id.hashCode & 0x7FFFFFFF,
        title: '${n.actorName} ${n.message}',
        body: n.preview.trim(),
      );
    }
  }
}
