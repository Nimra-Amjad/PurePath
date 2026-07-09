import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_constants.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';
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
    (Icons.all_inclusive, 'Unlimited habits', 'free plan: 5 active habits'),
    (Icons.groups, 'Exclusive challenges', 'Pro-only group challenges'),
    (
      Icons.ac_unit,
      '5 streak freezes / month',
      'plus auto-freeze on sick days',
    ),
    (Icons.widgets, 'Widgets & wearables', 'home-screen widgets, watch sync'),
  ];

  void _startFreeTrial() {
    // TODO: Hook up in-app purchase flow for [_selectedPlan].
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Purchases coming soon (${_selectedPlan.title} plan)'),
      ),
    );
  }

  void _restorePurchase() {
    // TODO: Hook up restore-purchase flow.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Purchases coming soon')));
  }

  Future<void> _openTerms() async {
    await launchUrl(
      Uri.parse(kPrivacyPolicyUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              _buildPlanCards(),
              const Space.vertical(24),
              PrimaryButton(
                text: 'Start 7-day free trial',
                onPressed: _startFreeTrial,
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

  Widget _buildPlanCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final plan in PaywallPlan.values) ...[
          if (plan != PaywallPlan.values.first) const Space.horizontal(14),
          Expanded(
            child: PaywallPlanCard(
              plan: plan,
              selected: _selectedPlan == plan,
              onTap: () => setState(() => _selectedPlan = plan),
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
