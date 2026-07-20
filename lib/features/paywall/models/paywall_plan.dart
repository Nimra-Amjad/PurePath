import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Static paywall plan metadata. Price and caption here are only fallbacks
/// shown while the live Play Store prices are loading (or if loading fails);
/// [PaywallPlanOption] overrides them with real store values.
enum PaywallPlan {
  monthly(
    title: 'Monthly',
    price: '\$6.00',
    caption: 'per month',
    badge: null,
    productId: 'purepath_pro_monthly',
  ),
  yearly(
    title: 'Yearly',
    price: '\$36.00',
    caption: '\$3.00 / month',
    badge: 'SAVE 50%',
    productId: 'purepath_pro_yearly',
  );

  const PaywallPlan({
    required this.title,
    required this.price,
    required this.caption,
    required this.badge,
    required this.productId,
  });

  final String title;
  final String price;
  final String caption;

  /// Google Play subscription product id this plan maps to.
  final String productId;

  /// Promo pill shown above the card (e.g. "SAVE 50%"), if any.
  final String? badge;
}

/// A paywall plan paired with its live RevenueCat [Package]. While offerings
/// are still loading (package == null) the enum's hardcoded price is shown,
/// so the paywall never renders empty.
class PaywallPlanOption {
  const PaywallPlanOption({required this.plan, this.package});

  final PaywallPlan plan;
  final Package? package;

  String get title => plan.title;
  String? get badge => plan.badge;

  /// Localized store price (e.g. "$29.99", "PKR 8,400") when available.
  String get price => package?.storeProduct.priceString ?? plan.price;

  String get caption {
    final product = package?.storeProduct;
    // Only the yearly caption is price-derived ("$2.50 / month").
    if (product == null || plan != PaywallPlan.yearly) return plan.caption;
    final perMonth = NumberFormat.simpleCurrency(
      name: product.currencyCode,
    ).format(product.price / 12);
    return '$perMonth / month';
  }
}
