import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/custom_vertical_divider.dart';
import 'package:purepath/core/widgets/space.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
            _badgesSection(),
            const SizedBox(height: 20),
            // _goalsSection(),
            // const SizedBox(height: 20),
            _settingsSection(),
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
            // style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// -------------------------- BADGES SECTION --------------------------
  Widget _badgesSection() {
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
            Text(
              "See all 12",
              style: AppTextStyles.normal.copyWith(color: purple),
            ),
          ],
        ),
        Space.vertical(12),
        Row(
          children: [
            _badge("🔥", "Streak King"),
            Space.horizontal(12),
            _badge("🧘", "Zen Master"),
            Space.horizontal(12),
            _badge("📚", "Bookworm"),
            Space.horizontal(12),
            _badge("🌅", "Early Bird"),
          ],
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
              style: AppTextStyles.normal.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------------- SETTINGS SECTION --------------------------
  Widget _settingsSection() {
    return Column(
      children: [
        _settingTile(Icons.notifications, "Reminders", false),
        _settingTile(Icons.palette, "Appearance", false),
        _settingTile(Icons.star, "Upgrade to Pro", false),
        _settingTile(Icons.lock, "Privacy & Data", false),
        _settingTile(Icons.people, "Invite Friends", false),
        _settingTile(Icons.logout, "Sign out", true),
      ],
    );
  }

  Widget _settingTile(IconData icon, String title, bool isDanger) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? Colors.red : textSecondary),
      title: Text(
        title,
        style: AppTextStyles.normal.copyWith(
          color: isDanger ? Colors.red : textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
