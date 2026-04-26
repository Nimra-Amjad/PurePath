import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/preferences/widgets/feature_detail_widget.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: kTealGlowColor,
                    border: Border.all(color: kDarkTealColor, width: 2),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(
                    Icons.check,
                    color: kDarkTealColor,
                    size: 40,
                  ),
                ),
                Space.vertical(10),
                Text(
                  "Your are all set,\nAhmed!🎉",
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 25,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                Space.vertical(10),
                Text(
                  "Here's what you can do with PurePath",
                  style: AppTextStyles.normal,
                  textAlign: TextAlign.center,
                ),
                Space.vertical(10),
                FeatureDetailWidget(
                  title: "Track your daily habits",
                  description:
                      "Check off habits each day and watch your streak grow",
                  icon: Icons.check_box,
                ),
                FeatureDetailWidget(
                  title: "See your progress",
                  description:
                      "Weekly charts and insights show how consistent your are",
                  icon: Icons.check_box,
                ),
                FeatureDetailWidget(
                  title: "Join challenges",
                  description:
                      "Compete with others and stay motivated together",
                  icon: Icons.check_box,
                ),
                FeatureDetailWidget(
                  title: "Get reminded on time",
                  description: "We'll nudge you so you never forget a habit",
                  icon: Icons.check_box,
                ),
                PrimaryButton(
                  text: "Next",
                  onPressed: () {
                    context.go(AppRoute.bottomNavBar.path);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
