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
    required bool isPro,
    required this.options,
    required this.status,
    this.errorMessage,
  }) : _isPro = isPro;

  /// Raw Pro entitlement as reported by the store. Prefer [isPro] for gating.
  final bool _isPro;

  /// Whether the current user should be treated as Pro. Gate Pro features on
  /// this: `context.watch<SubscriptionBloc>().state.isPro`
  ///
  /// In debug builds this is always `true` so the paywall never blocks
  /// development. Release builds use the real entitlement.
  bool get isPro => kDebugMode || _isPro;

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
      isPro: isPro ?? _isPro,
      options: options ?? this.options,
      status: status ?? this.status,
      // Intentionally not carried over — a message belongs to one emit.
      errorMessage: errorMessage,
    );
  }
}
