import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purepath/core/constants/app_constants.dart';
import 'package:purepath/core/providers/subscription_provider.dart';
import 'package:purepath/core/repositories/user_repository.dart';
import 'package:purepath/features/paywall/models/paywall_plan.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SubscriptionRepository
//
// Business logic for PurePath Pro subscriptions (Layer 2).
//   • Configures RevenueCat once at app start (DI creates this eagerly).
//   • Keeps the RevenueCat identity in sync with Firebase Auth so a
//     subscription follows the account, not the device.
//   • Exposes `isPro` (+ stream) that SubscriptionBloc broadcasts app-wide.
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionRepository {
  SubscriptionRepository({
    required SubscriptionProvider subscriptionProvider,
    required UserRepository userRepository,
  })  : _provider = subscriptionProvider,
        _userRepository = userRepository;

  final SubscriptionProvider _provider;
  final UserRepository _userRepository;

  StreamSubscription<User?>? _firebaseUserSub;
  StreamSubscription<CustomerInfo>? _customerInfoSub;

  bool _isPro = false;

  /// Whether the current user has the Pro entitlement right now.
  bool get isPro => _isPro;

  final _isProController = StreamController<bool>.broadcast();
  Stream<bool> get isProStream => _isProController.stream;

  /// Call once at startup. Safe to call on unsupported platforms (no-op) and
  /// never throws — a billing failure must not block app launch.
  Future<void> start() async {
    if (!_provider.isSupported) return;
    try {
      await _provider.configure();

      _customerInfoSub = _provider.customerInfoStream.listen(_onCustomerInfo);
      _firebaseUserSub = _userRepository.firebaseUserStream.listen(
        (user) => _syncIdentity(user),
      );

      // Cover a session restored before this listener attached, then prime
      // the cached isPro flag.
      await _syncIdentity(_userRepository.firebaseUser);
      _onCustomerInfo(await _provider.getCustomerInfo());
    } catch (e) {
      debugPrint('SubscriptionRepository.start error: $e');
    }
  }

  /// The paywall plans with live Play Store prices attached. Falls back to
  /// package-less options (hardcoded prices) for any plan RevenueCat doesn't
  /// return.
  Future<List<PaywallPlanOption>> getPlanOptions() async {
    final current = (await _provider.getOfferings()).current;
    return [
      for (final plan in PaywallPlan.values)
        PaywallPlanOption(plan: plan, package: _packageFor(current, plan)),
    ];
  }

  /// Launches the Play purchase sheet. Returns whether the user is Pro
  /// afterwards. Throws PlatformException on failure/cancel — the bloc maps
  /// those to user-facing messages.
  Future<bool> purchase(Package package) async {
    final result = await _provider.purchasePackage(package);
    _onCustomerInfo(result.customerInfo);
    return _isPro;
  }

  /// Re-links purchases made with this Play account. Returns whether the
  /// user is Pro afterwards.
  Future<bool> restore() async {
    _onCustomerInfo(await _provider.restorePurchases());
    return _isPro;
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _onCustomerInfo(CustomerInfo info) {
    // Case-insensitive so a dashboard id of "Pro" vs "pro" can't break gating.
    final active = info.entitlements.active.keys.any(
      (id) => id.toLowerCase() == kProEntitlementId.toLowerCase(),
    );
    // Debug-only override; a no-op in release builds (see app_constants.dart).
    final isPro = (kDebugMode && kDebugForceProOverride != null)
        ? kDebugForceProOverride!
        : active;
    if (isPro == _isPro) return;
    _isPro = isPro;
    _isProController.add(isPro);
    _mirrorAccessToFirestore(isPro);
  }

  /// Writes the current access state onto the user's Firestore `users` doc so
  /// it can be read outside the RevenueCat SDK (admin views, security rules,
  /// backend queries). RevenueCat stays the source of truth — this is a
  /// mirror: `true` right after a purchase/renewal, `false` once the
  /// subscription lapses (expiry, cancellation past the paid period, or an
  /// unresolved billing issue).
  ///
  /// Note: this only runs while the app is open. If a subscription expires
  /// while the app is closed, the flag updates the next time that user opens
  /// the app (when RevenueCat reports the change). For a client-only app that
  /// gates features in-app this is enough; real-time server accuracy would
  /// need a RevenueCat webhook → Cloud Function instead.
  void _mirrorAccessToFirestore(bool hasAccess) {
    // Fire-and-forget: updateUserDocument swallows its own errors and no-ops
    // when signed out, so a Firestore hiccup never blocks entitlement updates.
    unawaited(_userRepository.updateUserDocument({'allowAccess': hasAccess}));
  }

  Future<void> _syncIdentity(User? user) async {
    try {
      if (user != null) {
        await _provider.logIn(user.uid);
      } else if (!await _provider.isAnonymous) {
        await _provider.logOut();
      }
    } catch (e) {
      debugPrint('SubscriptionRepository identity sync error: $e');
    }
  }

  Package? _packageFor(Offering? offering, PaywallPlan plan) {
    if (offering == null) return null;
    // Standard package types ($rc_monthly / $rc_annual) when the offering
    // uses them...
    final standard = switch (plan) {
      PaywallPlan.monthly => offering.monthly,
      PaywallPlan.yearly => offering.annual,
    };
    if (standard != null) return standard;
    // ...otherwise match by Play product id (store ids look like
    // "purepath_pro_monthly:monthly", hence the split).
    for (final package in offering.availablePackages) {
      final productId = package.storeProduct.identifier.split(':').first;
      if (productId == plan.productId) return package;
    }
    return null;
  }

  void dispose() {
    _firebaseUserSub?.cancel();
    _customerInfoSub?.cancel();
    _isProController.close();
  }
}
