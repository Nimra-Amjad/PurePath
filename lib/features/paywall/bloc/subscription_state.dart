part of 'subscription_bloc.dart';

/// Transient paywall flow status. `success`/`empty`/`failure` values are
/// emitted once and the bloc resets to `idle`; the page reacts to them in a
/// BlocConsumer listener.
enum PaywallStatus {
  idle,
  loadingPlans,
  purchasing,
  restoring,
  purchaseSuccess,
  restoreSuccess,
  restoreEmpty,
  failure,
}

@immutable
class SubscriptionState {
  const SubscriptionState({
    required this.isPro,
    required this.options,
    required this.status,
    this.errorMessage,
  });

  /// Whether the current user has an active Pro entitlement. Gate Pro
  /// features on this: `context.watch<SubscriptionBloc>().state.isPro`
  final bool isPro;

  /// One option per [PaywallPlan]; packages are null until prices load.
  final List<PaywallPlanOption> options;

  final PaywallStatus status;
  final String? errorMessage;

  bool get isBusy =>
      status == PaywallStatus.purchasing || status == PaywallStatus.restoring;

  factory SubscriptionState.initial() => SubscriptionState(
        isPro: false,
        options: [
          for (final plan in PaywallPlan.values) PaywallPlanOption(plan: plan),
        ],
        status: PaywallStatus.idle,
      );

  SubscriptionState copyWith({
    bool? isPro,
    List<PaywallPlanOption>? options,
    PaywallStatus? status,
    String? errorMessage,
  }) {
    return SubscriptionState(
      isPro: isPro ?? this.isPro,
      options: options ?? this.options,
      status: status ?? this.status,
      // Intentionally not carried over — a message belongs to one emit.
      errorMessage: errorMessage,
    );
  }
}
