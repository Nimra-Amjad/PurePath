import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      title: 'Begin your journey',
      subtitle:
          'Every big change starts with a single small step. Set your daily intentions and let our feline friend help you stay focused on what truly matters to you.',
      actionLabel: 'Next',
      image: Assets.onboarding1Icon,
    ),
    _OnboardingSlide(
      title: 'Master Your Routine',
      subtitle:
          'Transform your life through the power of repetition. Wake up with purpose, smash your goals, and turn those tiny actions into lifelong healthy habits.',
      actionLabel: 'Next',
      image: Assets.onboarding2Icon,
      isLast: true,
    ),
    _OnboardingSlide(
      title: 'Track your progress',
      subtitle:
          'Consistency is the secret sauce to success. Log your habits daily with a single tap to build a visual history of your dedication and hard work.',
      actionLabel: 'Finish',
      image: Assets.onboarding3Icon,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTapSkip() {
    if (_currentIndex == 0) {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    AppRoute.login.go(context);
  }

  void _onTapAction() {
    if (_currentIndex == _slides.length - 1) {
      AppRoute.login.go(context);
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Space.vertical(20),
                        _OnboardingIllustrationCard(image: slide.image),
                        Space.vertical(30),
                        Text(
                          slide.title,
                          style: AppTextStyles.bold.copyWith(
                            fontSize: 25,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Space.vertical(12),
                        Text(
                          slide.subtitle,
                          style: AppTextStyles.normal.copyWith(
                            fontSize: 16,
                            letterSpacing: 1.3,
                            color: kBlackColor.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Space.vertical(8),
              _OnboardingActions(
                label: _slides[_currentIndex].actionLabel,
                isLast: _slides[_currentIndex].isLast,
                onSkip: _onTapSkip,
                onAction: _onTapAction,
              ),
              Space.vertical(8),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions({
    required this.label,
    required this.isLast,
    required this.onSkip,
    required this.onAction,
  });

  final String label;
  final bool isLast;
  final VoidCallback onSkip;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onSkip,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Text(
              'Skip now',
              style: AppTextStyles.normal.copyWith(
                fontSize: 16,
                color: kBlackColor.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
        const Spacer(),
        PrimaryButton(
          text: label,
          onPressed: onAction,
          isMainAxisSizeMin: true,
        ),
      ],
    );
  }
}

class _OnboardingIllustrationCard extends StatelessWidget {
  const _OnboardingIllustrationCard({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(child: Image.asset(image)),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.image,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final String image;
  final bool isLast;
}
