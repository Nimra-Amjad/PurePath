import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/widgets/app_dialog.dart';
import 'package:purepath/core/widgets/custom_vertical_divider.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/profile/pages/badges_page.dart';
import 'package:purepath/features/profile/pages/reminders_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // ── Sign-out dialog ────────────────────────────────────────────────────────

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await AppDialog.show(
      context,
      icon: Icons.logout_rounded,
      iconColor: red,
      title: 'Sign out?',
      subtitle: "You'll be logged out and need to sign back in to continue.",
      confirmText: 'Sign out',
      confirmColor: red,
    );

    if (confirmed == true && context.mounted) {
      context.read<UserBloc>().add(LogoutRequested());
      context.go(AppRoute.login.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _profileHeader(),
            const SizedBox(height: 20),
            _statsRow(),
            const SizedBox(height: 20),
            _tierCard(),
            const SizedBox(height: 20),
            _badgesSection(context),
            const SizedBox(height: 20),
            _settingsSection(context),
          ],
        ),
      ),
    );
  }

  /// -------------------------- PROFILE HEADER WIDGET --------------------------
  Widget _profileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: lightPurple,
          child: Text(
            "A",
            style: AppTextStyles.semiBold.copyWith(fontSize: 28, color: purple),
          ),
        ),
        Space.vertical(12),
        Text("Ahmad Raza", style: AppTextStyles.bold.copyWith(fontSize: 20)),
        Space.vertical(4),
        Text(
          "@ahmad.builds",
          style: AppTextStyles.normal.copyWith(color: textSecondary),
        ),
        Space.vertical(6),
        Text(
          "Lahore, Pakistan • Joined Jan 2026",
          style: AppTextStyles.normal.copyWith(
            color: textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// -------------------------- STAT WIDGET --------------------------
  Widget _statsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("23", "Day Streak", orange),
          CustomVerticalDivider(),
          _statItem("6", "Habits", green),
          CustomVerticalDivider(),
          _statItem("142", "Check-ins", purple),
          CustomVerticalDivider(),
          _statItem("6", "Badges", red),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.bold.copyWith(fontSize: 18, color: color),
        ),
        Space.vertical(4),
        Text(label, style: AppTextStyles.normal.copyWith(fontSize: 12)),
      ],
    );
  }

  /// -------------------------- TIER WIDGET --------------------------
  Widget _tierCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightPurple,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.diamond, color: purple),
              Space.horizontal(10),
              Text(
                "Silver Ritualist",
                style: AppTextStyles.bold.copyWith(color: purple),
              ),
            ],
          ),
          Space.vertical(10),
          LinearProgressIndicator(
            value: 0.83,
            color: green,
            backgroundColor: kWhiteColor,
          ),
          Space.vertical(6),
          Text(
            "1,660 XP earned • 2,000 XP for Gold",
            style: AppTextStyles.normal.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// -------------------------- BADGES SECTION --------------------------
  Widget _badgesSection(BuildContext context) {
    final previews = BadgesPage.earnedPreviews();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "BADGES & ACHIEVEMENTS",
              style: AppTextStyles.bold.copyWith(
                color: textSecondary,
                fontSize: 12,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const BadgesPage())),
              child: Text(
                "See all ${BadgesPage.totalCount}",
                style: AppTextStyles.medium.copyWith(
                  color: purple,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        Space.vertical(12),
        Row(
          children: previews
              .expand(
                (p) => [
                  _badge(p.$1, p.$2),
                  if (p != previews.last) Space.horizontal(12),
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _badge(String emoji, String label) {
    return Expanded(
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: AppTextStyles.normal.copyWith(fontSize: 20)),
            Space.vertical(6),
            Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.normal.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------------- SETTINGS SECTION --------------------------
  Widget _settingsSection(BuildContext context) {
    return Column(
      children: [
        _settingTile(
          context: context,
          icon: Icons.notifications_rounded,
          title: "Reminders",
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RemindersPage())),
        ),
        _settingTile(
          context: context,
          icon: Icons.star_rounded,
          title: "Upgrade to Pro",
        ),
        _settingTile(
          context: context,
          icon: Icons.lock_rounded,
          title: "Privacy & Data",
        ),
        _settingTile(
          context: context,
          icon: Icons.people_rounded,
          title: "Invite Friends",
        ),
        _settingTile(
          context: context,
          icon: Icons.logout_rounded,
          title: "Sign out",
          isDanger: true,
          onTap: () => _confirmSignOut(context),
        ),
      ],
    );
  }

  Widget _settingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    bool isDanger = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isDanger ? red : textSecondary),
      title: Text(
        title,
        style: AppTextStyles.normal.copyWith(
          color: isDanger ? red : textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: textSecondary),
    );
  }
}
