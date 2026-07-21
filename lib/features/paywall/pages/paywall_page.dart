import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_constants.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/paywall/bloc/subscription_bloc.dart';
import 'package:purepath/features/paywall/models/paywall_plan.dart';
import 'package:purepath/features/paywall/widgets/paywall_feature_row.dart';
import 'package:purepath/features/paywall/widgets/paywall_plan_card.dart';
import 'package:url_launcher/url_launcher.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  PaywallPlan _selectedPlan = PaywallPlan.yearly;

  static const _features = <(IconData, String, String)>[
    (Icons.auto_awesome, 'Unlimited AI coach', 'free plan: 3 chats/day'),
    (
      Icons.insights,
      'Advanced analytics',
      'mood × habit patterns, yearly view, PDF reports',
    ),
    (Icons.all_inclusive, 'Unlimited habits', 'free plan: 3 active habits'),
    (Icons.groups, 'Exclusive challenges', 'Pro-only group challenges'),
    (
      Icons.ac_unit,
      '5 streak freezes / month',
      'plus auto-freeze on sick days',
    ),
    (Icons.widgets, 'Widgets & wearables', 'home-screen widgets, watch sync'),
  ];

  @override
  void initState() {
    super.initState();
    // Load live Play Store prices (no-op if already loaded).
    context.read<SubscriptionBloc>().add(PaywallPlansRequested());
  }

  void _startFreeTrial(SubscriptionState state) {
    final option = state.options.firstWhere((o) => o.plan == _selectedPlan);
    context.read<SubscriptionBloc>().add(PurchaseRequested(option));
  }

  void _restorePurchase() {
    context.read<SubscriptionBloc>().add(RestoreRequested());
  }

  Future<void> _openTerms() async {
    await launchUrl(
      Uri.parse(kPrivacyPolicyUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  void _onStatusChanged(BuildContext context, SubscriptionState state) {
    switch (state.status) {
      case PaywallStatus.purchaseSuccess:
        AppSnackBar.success(context, 'Welcome to PurePath Pro!');
        context.pop();
      case PaywallStatus.restoreSuccess:
        AppSnackBar.success(context, 'Your subscription has been restored.');
        context.pop();
      case PaywallStatus.restoreEmpty:
        AppSnackBar.warning(
          context,
          'No active subscription found for this account.',
        );
      case PaywallStatus.failure:
        AppSnackBar.error(
          context,
          state.errorMessage ?? 'Something went wrong. Please try again.',
        );
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onStatusChanged,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: kScaffoldColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close, color: kLightGreyColor),
                    ),
                  ),
                  _buildHeader(),
                  const Space.vertical(28),
                  for (final (icon, title, detail) in _features) ...[
                    PaywallFeatureRow(icon: icon, title: title, detail: detail),
                    const Space.vertical(16),
                  ],
                  const Space.vertical(12),
                  _buildPlanCards(state),
                  const Space.vertical(24),
                  PrimaryButton(
                    text: 'Start 3-day free trial',
                    onPressed: () => _startFreeTrial(state),
                    isLoading: state.isBusy,
                    height: 54,
                    borderRadius: 27,
                    textFontWeight: FontWeight.w700,
                  ),
                  const Space.vertical(14),
                  _buildFooterLinks(),
                  const Space.vertical(24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 76,
          width: 76,
          decoration: BoxDecoration(
            color: kPrimaryGreenColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.workspace_premium,
            color: kScaffoldColor,
            size: 40,
          ),
        ),
        const Space.vertical(18),
        Text(
          'PurePath Pro',
          textAlign: TextAlign.center,
          style: AppTextStyles.bold.copyWith(color: kWhiteColor, fontSize: 26),
        ),
        const Space.vertical(4),
        Text(
          'Everything you need to make habits stick',
          textAlign: TextAlign.center,
          style: AppTextStyles.normal.copyWith(
            color: kLightGreyColor,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCards(SubscriptionState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final option in state.options) ...[
          if (option != state.options.first) const Space.horizontal(14),
          Expanded(
            child: PaywallPlanCard(
              option: option,
              selected: _selectedPlan == option.plan,
              onTap: () => setState(() => _selectedPlan = option.plan),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooterLinks() {
    final linkStyle = AppTextStyles.normal.copyWith(
      color: kSecondaryGreyColor,
      fontSize: 13,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Cancel anytime', style: linkStyle),
        Text(' · ', style: linkStyle),
        GestureDetector(
          onTap: _restorePurchase,
          child: Text('Restore purchase', style: linkStyle),
        ),
        Text(' · ', style: linkStyle),
        GestureDetector(
          onTap: _openTerms,
          child: Text('Terms', style: linkStyle),
        ),
      ],
    );
  }
}
