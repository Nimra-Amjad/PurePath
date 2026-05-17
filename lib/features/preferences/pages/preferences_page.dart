import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/widgets/custom_back_button.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/notifications/bloc/notification_bloc.dart';
import 'package:purepath/features/preferences/views/challenge_view.dart';
import 'package:purepath/features/preferences/views/goal_view.dart';
import 'package:purepath/features/preferences/views/notification_view.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // ── Onboarding selections ─────────────────────────────────────────────────
  // Initialised with the default (first) option of each view so we always
  // have a value even if the user never taps anything.
  String _selectedGoal = '🏃‍♂️ Fitness & Health';
  String _selectedChallenge = 'I forget to do them';

  // ── Steps ─────────────────────────────────────────────────────────────────
  // GoalView and ChallengeView get callbacks to bubble selections up here.
  // NotificationView is stateless — the button itself captures allow/skip.

  List<Widget> get _steps => [
    GoalView(onGoalChanged: (v) => _selectedGoal = v),
    ChallengeView(onChallengeChanged: (v) => _selectedChallenge = v),
    const NotificationView(),
  ];

  // ── Navigation ────────────────────────────────────────────────────────────

  void _next() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish({required bool notificationsEnabled}) {
    // Persist goal + challenge + onboarding completion via UserBloc.
    context.read<UserBloc>().add(
      SaveOnboardingData(goal: _selectedGoal, challenge: _selectedChallenge),
    );

    // Hand the master-toggle decision to the notification bloc — it owns
    // the OS schedule + Firestore flag end-to-end. Fire-and-forget: the
    // user keeps moving while it works in the background.
    context.read<NotificationBloc>().add(
      NotificationToggled(enabled: notificationsEnabled),
    );

    context.push(AppRoute.welcome.path);
  }

  void _back() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps; // evaluated once per build

    return Scaffold(
      backgroundColor: kScaffoldColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header bar (back + progress) ─────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _currentStep == 0
                      ? const SizedBox(width: 35, height: 35)
                      : CustomBackButton(onTap: _back),
                  Space.horizontal(16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          end: steps.length > 1
                              ? _currentStep / (steps.length - 1)
                              : 0,
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        builder: (context, value, _) {
                          return SizedBox(
                            height: 6,
                            child: Stack(
                              children: [
                                Container(color: kLightGreyColor),
                                FractionallySizedBox(
                                  widthFactor: value.clamp(0.0, 1.0),
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          kLightGreenColor,
                                          kDarkGreenColor,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Space.horizontal(16),
                  const Icon(Icons.abc, color: kTransparentColor),
                ],
              ),
            ),

            // ── Page content ──────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: steps[index],
                  );
                },
              ),
            ),

            // ── Bottom action bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    text: _currentStep == 2 ? 'Allow notifications' : 'Next',
                    onPressed: _currentStep == 2
                        ? () => _finish(notificationsEnabled: true)
                        : _next,
                  ),
                  if (_currentStep == 2) ...[
                    Space.vertical(10),
                    PrimaryButton(
                      text: 'Skip for now',
                      onPressed: () => _finish(notificationsEnabled: false),
                      showBorder: true,
                      buttonColor: kWhiteColor,
                      borderColor: kPrimaryColor,
                      textColor: kPrimaryColor,
                    ),
                  ],
                ],
              ),
            ),
            Space.vertical(20),
          ],
        ),
      ),
    );
  }
}