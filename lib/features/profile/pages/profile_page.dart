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
            _profileHeader(context),
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
  Widget _profileHeader(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (a, b) => a.user != b.user,
      builder: (context, state) {
        final user = state.user;
        final fullName = (user?.fullName ?? '').trim();
        final email = user?.email ?? '';
        final displayName = fullName.isEmpty ? 'Welcome' : fullName;
        final initial =
            fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

        return Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: lightPurple,
              child: Text(
                initial,
                style: AppTextStyles.semiBold.copyWith(
                  fontSize: 28,
                  color: purple,
                ),
              ),
            ),
            Space.vertical(12),
            Text(
              displayName,
              style: AppTextStyles.bold.copyWith(fontSize: 20),
            ),
            if (email.isNotEmpty) ...[
              Space.vertical(4),
              Text(
                email,
                style: AppTextStyles.normal.copyWith(color: textSecondary),
              ),
            ],
          ],
        );
      },
    );
  }

  /// -------------------------- STAT WIDGET --------------------------
  Widget _statsRow() {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (a, b) => a.user?.coins != b.user?.coins,
      builder: (context, state) {
        final coins = state.user?.coins ?? 0;
        final earnedBadges = BadgesPage.earnedCountForCoins(coins);
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
              _statItem('$coins', 'Day Streak', orange),
              CustomVerticalDivider(),
              _statItem('$earnedBadges', 'Badges', purple),
            ],
          ),
        );
      },
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
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (a, b) => a.user?.coins != b.user?.coins,
      builder: (context, state) {
        final coins = state.user?.coins ?? 0;
        final tier = _Tier.forCoins(coins);
        final next = tier.next;

        final progress = next == null
            ? 1.0
            : ((coins - tier.min) / (next.min - tier.min)).clamp(0.0, 1.0);

        final subtitle = next == null
            ? 'Top tier reached — keep the streak alive!'
            : '$coins-day streak • ${next.min} days for ${next.name}';

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
                  Icon(tier.icon, color: tier.color),
                  Space.horizontal(10),
                  Text(
                    tier.name,
                    style: AppTextStyles.bold.copyWith(color: tier.color),
                  ),
                ],
              ),
              Space.vertical(10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  color: tier.color,
                  backgroundColor: kWhiteColor,
                ),
              ),
              Space.vertical(6),
              Text(
                subtitle,
                style: AppTextStyles.normal.copyWith(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  /// -------------------------- BADGES SECTION --------------------------
  Widget _badgesSection(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (a, b) => a.user?.coins != b.user?.coins,
      builder: (context, _) {
        final previews = BadgesPage.earnedPreviews(context);
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
            if (previews.isEmpty)
              _EmptyBadgePreview()
            else
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
      },
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

// ─────────────────────────────────────────────────────────────────────────────
// Tier ladder — drives the purple progress card
//
// One tier per consecutive-day streak band. The top of one tier is the
// bottom of the next, so progress within a tier is just a normalised
// fraction of how far the user has climbed inside their current band.
// ─────────────────────────────────────────────────────────────────────────────

class _Tier {
  final String name;
  final int min;
  final Color color;
  final IconData icon;

  const _Tier({
    required this.name,
    required this.min,
    required this.color,
    required this.icon,
  });

  static const _ladder = <_Tier>[
    _Tier(name: 'Initiate',
        min: 0,
        color: Color(0xFF9B82E8),
        icon: Icons.auto_awesome_rounded),
    _Tier(name: 'Apprentice',
        min: 10,
        color: Color(0xFFCD7F32), // bronze
        icon: Icons.eco_rounded),
    _Tier(name: 'Bronze Ritualist',
        min: 30,
        color: Color(0xFFB87333),
        icon: Icons.shield_rounded),
    _Tier(name: 'Silver Ritualist',
        min: 90,
        color: Color(0xFF8E9AAF),
        icon: Icons.diamond_rounded),
    _Tier(name: 'Gold Ritualist',
        min: 365,
        color: Color(0xFFD4A017),
        icon: Icons.emoji_events_rounded),
    _Tier(name: 'Platinum Master',
        min: 1000,
        color: Color(0xFF6C4DFF),
        icon: Icons.workspace_premium_rounded),
    _Tier(name: 'Diamond Legend',
        min: 2500,
        color: Color(0xFF00BCD4),
        icon: Icons.stars_rounded),
  ];

  /// The tier whose [min] is the largest value <= [coins].
  static _Tier forCoins(int coins) {
    var current = _ladder.first;
    for (final t in _ladder) {
      if (coins >= t.min) current = t;
    }
    return current;
  }

  /// The tier the user is currently working towards, or null if already at
  /// the top.
  _Tier? get next {
    final i = _ladder.indexOf(this);
    return (i >= 0 && i < _ladder.length - 1) ? _ladder[i + 1] : null;
  }
}

class _EmptyBadgePreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 24)),
          Space.vertical(6),
          Text(
            'Build a 10-day streak to earn your first badge',
            style: AppTextStyles.medium.copyWith(
              fontSize: 12,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
