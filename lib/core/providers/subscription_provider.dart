import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purepath/core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SubscriptionProvider
//
// Raw wrapper around the RevenueCat SDK — Layer 1, same role as
// FirebaseAuthProvider plays for Firebase. Owns SDK configuration and
// broadcasts CustomerInfo updates. No business logic lives here; that's
// SubscriptionRepository's job.
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionProvider {
  SubscriptionProvider();

  final _customerInfoController = StreamController<CustomerInfo>.broadcast();

  /// Fires whenever RevenueCat learns about a purchase, renewal, expiry or
  /// restore — including changes made outside the app (e.g. a cancellation
  /// in the Play Store).
  Stream<CustomerInfo> get customerInfoStream =>
      _customerInfoController.stream;

  /// Purchases are Android-only for now (the app ships only to Play Store).
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<void> configure() async {
    if (!isSupported) return;
    if (await Purchases.isConfigured) return;

    if (kDebugMode) await Purchases.setLogLevel(LogLevel.debug);

    await Purchases.configure(
      PurchasesConfiguration(kRevenueCatAndroidApiKey),
    );
    Purchases.addCustomerInfoUpdateListener(_customerInfoController.add);
  }

  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  Future<Offerings> getOfferings() => Purchases.getOfferings();

  Future<PurchaseResult> purchasePackage(Package package) =>
      Purchases.purchase(PurchaseParams.package(package));

  Future<CustomerInfo> restorePurchases() => Purchases.restorePurchases();

  Future<LogInResult> logIn(String appUserId) => Purchases.logIn(appUserId);

  Future<CustomerInfo> logOut() => Purchases.logOut();

  Future<bool> get isAnonymous => Purchases.isAnonymous;

  void dispose() {
    _customerInfoController.close();
  }
}
