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
  ];

  void _next() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.push(AppRoute.home.path);
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
      backgroundColor: const Color(0xFFF5EDE8), // warm peach from design
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP BAR (fixed) ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _currentStep == 0
                      ? Icon(Icons.abc, color: kTransparentColor)
                      : GestureDetector(
                          onTap: _back,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: kWhiteColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: kBlackColor.withOpacityValue(0.08),
                                  blurRadius: 2,
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
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor: kLightYellowColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFD4608A),
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

            // ── MIDDLE CONTENT (scrollable, swipeable) ───────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // controlled by buttons
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
              child: PrimaryButton(
                text: _currentStep == _steps.length - 1 ? 'Finish' : 'Next',
                onPressed: _next,
              ),
            ),
            Space.vertical(30),
          ],
        ),
      ),
    );
  }
}
