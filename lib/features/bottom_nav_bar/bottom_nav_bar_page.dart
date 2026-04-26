import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/utils/utils.dart';
import 'package:purepath/features/community/pages/community_page.dart';
import 'package:purepath/features/home/pages/home_page.dart';
import 'package:purepath/features/insights/pages/insights_page.dart';
import 'package:purepath/features/profile/pages/profile_page.dart';

class BottomNavBarPage extends StatefulWidget {
  const BottomNavBarPage({super.key});

  @override
  State<BottomNavBarPage> createState() => _BottomNavBarPageState();
}

class _BottomNavBarPageState extends State<BottomNavBarPage> {
  int _index = 0;

  static const _tabs = <_HomeTab>[
    _HomeTab(label: 'Home', icon: Assets.svgHomeIcon),
    _HomeTab(label: 'Insights', icon: Assets.svgInsightsIcon),
    _HomeTab(label: 'Community', icon: Assets.svgCommunityIcon),
    _HomeTab(label: 'Profile', icon: Assets.svgUserIcon),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: const [
            HomePage(),
            InsightsPage(),
            CommunityPage(),
            ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: kWhiteColor,
          boxShadow: [
            BoxShadow(
              color: kBlackColor.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
            ),
            child: BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              backgroundColor: kWhiteColor,
              selectedItemColor: kPrimaryColor,
              unselectedItemColor: kBlackColor.withValues(alpha: 0.45),
              selectedLabelStyle: AppTextStyles.medium.copyWith(fontSize: 12),
              unselectedLabelStyle: AppTextStyles.normal.copyWith(fontSize: 12),
              items: [
                for (final tab in _tabs)
                  BottomNavigationBarItem(
                    icon: SvgPicture.asset(
                      tab.icon,
                      colorFilter: colorFilter(color: kGreyColor),
                      width: 30,
                      height: 30,
                    ),
                    activeIcon: SvgPicture.asset(
                      tab.icon,
                      colorFilter: colorFilter(color: kPrimaryColor),
                      width: 30,
                      height: 30,
                    ),
                    label: tab.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTab {
  const _HomeTab({required this.label, required this.icon});

  final String label;
  final String icon;
}

class _HomeTabBody extends StatelessWidget {
  const _HomeTabBody({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: AppTextStyles.bold.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.normal.copyWith(
                color: kBlackColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
