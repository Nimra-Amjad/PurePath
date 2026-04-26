import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/preferences/views/goal_view.dart';
import 'package:purepath/features/preferences/views/challenge_view.dart';
import 'package:purepath/features/preferences/views/notification_view.dart';
import 'package:purepath/features/preferences/views/reminder_setup_view.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // ── Add/remove steps here only ──────────────────────────────────────────
  final List<Widget> _steps = const [
    GoalView(),
    ChallengeView(),
    NotificationView(),
    ReminderSetupView(),
  ];

  void _next() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.push(AppRoute.bottomNavBar.path);
    }
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
    return Scaffold(
      backgroundColor: kWhiteColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _currentStep == 0
                      ? SizedBox(width: 40, height: 40)
                      : GestureDetector(
                          onTap: _back,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: kWhiteColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: kBlackColor.withOpacityValue(0.2),
                                  blurRadius: 2,
                                  spreadRadius: 0,
                                  blurStyle: BlurStyle.outer,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              size: 22,
                              color: kDarkGreyColor,
                            ),
                          ),
                        ),
                  Space.horizontal(16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          end: _steps.length > 1
                              ? _currentStep / (_steps.length - 1)
                              : 0,
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return SizedBox(
                            height: 6,
                            child: Stack(
                              children: [
                                Container(color: kLightYellowColor),
                                FractionallySizedBox(
                                  widthFactor: value.clamp(0.0, 1.0),
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [kPinkColor, kPrimaryColor],
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
                  Icon(Icons.abc, color: kTransparentColor),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: _steps[index],
                  );
                },
              ),
            ),

            // ── BOTTOM BAR (fixed) ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    text: switch (_currentStep) {
                      2 => 'Allow notifications',
                      3 => 'Finish setup',
                      _ => 'Next',
                    },
                    onPressed: _next,
                  ),
                  if (_currentStep == 2) ...[
                    Space.vertical(10),
                    PrimaryButton(
                      text: "Skip for now",
                      onPressed: _next,
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
