enum PaywallPlan {
  monthly(
    title: 'Monthly',
    price: '\$4.99',
    caption: 'per month',
    badge: null,
  ),
  yearly(
    title: 'Yearly',
    price: '\$29.99',
    caption: '\$2.50 / month',
    badge: 'SAVE 50%',
  );

  const PaywallPlan({
    required this.title,
    required this.price,
    required this.caption,
    required this.badge,
  });

  final String title;
  final String price;
  final String caption;

  /// Promo pill shown above the card (e.g. "SAVE 50%"), if any.
  final String? badge;
}
