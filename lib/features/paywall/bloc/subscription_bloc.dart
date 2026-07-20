import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purepath/core/repositories/subscription_repository.dart';
import 'package:purepath/features/paywall/models/paywall_plan.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SubscriptionBloc
//
// Global BLoC — lives at the app root inside DI so any widget can gate Pro
// features via context.watch<SubscriptionBloc>().state.isPro.
//
// Responsibilities:
//   • isPro — mirrors SubscriptionRepository so purchases/expiry update the UI
//   • Paywall — loads live plan prices, runs purchase & restore flows
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc({required this.subscriptionRepository})
      : super(SubscriptionState.initial()) {
    on<SubscriptionStarted>(_onStarted);
    on<PaywallPlansRequested>(_onPlansRequested);
    on<PurchaseRequested>(_onPurchaseRequested);
    on<RestoreRequested>(_onRestoreRequested);
    on<_ProStatusChanged>(_onProStatusChanged);
  }

  final SubscriptionRepository subscriptionRepository;

  StreamSubscription<bool>? _isProSub;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  void _onStarted(SubscriptionStarted event, Emitter<SubscriptionState> emit) {
    _isProSub = subscriptionRepository.isProStream.listen(
      (isPro) => add(_ProStatusChanged(isPro)),
    );
    emit(state.copyWith(isPro: subscriptionRepository.isPro));
  }

  void _onProStatusChanged(
    _ProStatusChanged event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(state.copyWith(isPro: event.isPro));
  }

  // ── Paywall plans ──────────────────────────────────────────────────────────

  Future<void> _onPlansRequested(
    PaywallPlansRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    // Already loaded — don't refetch every time the paywall opens.
    if (state.options.every((o) => o.package != null)) return;

    emit(state.copyWith(status: PaywallStatus.loadingPlans));
    try {
      final options = await subscriptionRepository.getPlanOptions();
      emit(state.copyWith(status: PaywallStatus.idle, options: options));
    } catch (e) {
      // Keep the fallback prices on screen; purchase taps will explain.
      debugPrint('SubscriptionBloc.PaywallPlansRequested error: $e');
      emit(state.copyWith(status: PaywallStatus.idle));
    }
  }

  // ── Purchase / restore ─────────────────────────────────────────────────────

  Future<void> _onPurchaseRequested(
    PurchaseRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    final package = event.option.package;
    if (package == null) {
      emit(state.copyWith(
        status: PaywallStatus.failure,
        errorMessage:
            'Plans are still loading. Check your connection and try again.',
      ));
      emit(state.copyWith(status: PaywallStatus.idle));
      return;
    }

    emit(state.copyWith(status: PaywallStatus.purchasing));
    try {
      final isPro = await subscriptionRepository.purchase(package);
      emit(state.copyWith(
        status: isPro ? PaywallStatus.purchaseSuccess : PaywallStatus.failure,
        errorMessage: isPro ? null : 'Purchase could not be verified yet.',
        isPro: isPro,
      ));
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        // User closed the Play sheet — not an error.
        emit(state.copyWith(status: PaywallStatus.idle));
        return;
      }
      emit(state.copyWith(
        status: PaywallStatus.failure,
        errorMessage: _mapError(code),
      ));
    } catch (e) {
      debugPrint('SubscriptionBloc.PurchaseRequested error: $e');
      emit(state.copyWith(
        status: PaywallStatus.failure,
        errorMessage: 'Something went wrong. Please try again.',
      ));
    } finally {
      if (state.status == PaywallStatus.failure) {
        emit(state.copyWith(status: PaywallStatus.idle));
      }
    }
  }

  Future<void> _onRestoreRequested(
    RestoreRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: PaywallStatus.restoring));
    try {
      final isPro = await subscriptionRepository.restore();
      emit(state.copyWith(
        status:
            isPro ? PaywallStatus.restoreSuccess : PaywallStatus.restoreEmpty,
        isPro: isPro,
      ));
    } catch (e) {
      debugPrint('SubscriptionBloc.RestoreRequested error: $e');
      emit(state.copyWith(
        status: PaywallStatus.failure,
        errorMessage: 'Could not restore purchases. Please try again.',
      ));
      emit(state.copyWith(status: PaywallStatus.idle));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _mapError(PurchasesErrorCode code) {
    switch (code) {
      case PurchasesErrorCode.networkError:
      case PurchasesErrorCode.offlineConnectionError:
        return 'No internet connection. Check your network and retry.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchases are not allowed on this device.';
      case PurchasesErrorCode.paymentPendingError:
        return 'Payment is pending. You\'ll get Pro once it completes.';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'You already own this. Try "Restore purchase" below.';
      case PurchasesErrorCode.storeProblemError:
        return 'The Play Store had a problem. Please try again later.';
      case PurchasesErrorCode.configurationError:
      case PurchasesErrorCode.invalidCredentialsError:
        return 'Purchases aren\'t configured yet. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _isProSub?.cancel();
    return super.close();
  }
}
