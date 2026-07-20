part of 'subscription_bloc.dart';

@immutable
sealed class SubscriptionEvent {}

/// Fired once from DI when the app starts — subscribes to the repository's
/// isPro stream so purchases/expiries update the whole app.
class SubscriptionStarted extends SubscriptionEvent {}

/// Fired when the paywall opens — loads live Play Store prices (no-op if
/// they're already loaded).
class PaywallPlansRequested extends SubscriptionEvent {}

/// Fired when the user taps the trial/subscribe button.
class PurchaseRequested extends SubscriptionEvent {
  final PaywallPlanOption option;
  PurchaseRequested(this.option);
}

/// Fired by "Restore purchase".
class RestoreRequested extends SubscriptionEvent {}

/// Internal — repository reported an entitlement change.
class _ProStatusChanged extends SubscriptionEvent {
  final bool isPro;
  _ProStatusChanged(this.isPro);
}
