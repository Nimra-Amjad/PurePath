import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/repositories/firebase_auth_repository.dart';
import 'package:purepath/core/repositories/user_repository.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/app_dialog.dart';
import 'package:purepath/core/widgets/custom_textfield.dart';
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
        final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

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
            Text(displayName, style: AppTextStyles.bold.copyWith(fontSize: 20)),
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
          icon: Icons.person_outline_rounded,
          title: 'Edit Username',
          onTap: () => _showChangeUsernameSheet(context),
        ),
        _settingTile(
          context: context,
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          onTap: () => _showChangePasswordSheet(context),
        ),
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
        _settingTile(
          context: context,
          icon: Icons.delete_forever_rounded,
          title: 'Delete Account',
          isDanger: true,
          onTap: () => _showDeleteAccountSheet(context),
        ),
      ],
    );
  }

  // ── Sheets ────────────────────────────────────────────────────────────────

  void _showChangeUsernameSheet(BuildContext context) {
    AppBottomSheet.show(
      context,
      body: const _ChangeUsernameSheet(),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    AppBottomSheet.show(
      context,
      body: const _ChangePasswordSheet(),
    );
  }

  void _showDeleteAccountSheet(BuildContext context) {
    AppBottomSheet.show(
      context,
      body: const _DeleteAccountSheet(),
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
    _Tier(
      name: 'Initiate',
      min: 0,
      color: Color(0xFF9B82E8),
      icon: Icons.auto_awesome_rounded,
    ),
    _Tier(
      name: 'Apprentice',
      min: 10,
      color: Color(0xFFCD7F32), // bronze
      icon: Icons.eco_rounded,
    ),
    _Tier(
      name: 'Bronze Ritualist',
      min: 30,
      color: Color(0xFFB87333),
      icon: Icons.shield_rounded,
    ),
    _Tier(
      name: 'Silver Ritualist',
      min: 90,
      color: Color(0xFF8E9AAF),
      icon: Icons.diamond_rounded,
    ),
    _Tier(
      name: 'Gold Ritualist',
      min: 365,
      color: Color(0xFFD4A017),
      icon: Icons.emoji_events_rounded,
    ),
    _Tier(
      name: 'Platinum Master',
      min: 1000,
      color: Color(0xFF6C4DFF),
      icon: Icons.workspace_premium_rounded,
    ),
    _Tier(
      name: 'Diamond Legend',
      min: 2500,
      color: Color(0xFF00BCD4),
      icon: Icons.stars_rounded,
    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Change-username sheet
//
// Pre-fills with the current name. Updates Firestore + local UserBloc state
// on save so every avatar/initial in the app refreshes automatically.
// ─────────────────────────────────────────────────────────────────────────────

class _ChangeUsernameSheet extends StatefulWidget {
  const _ChangeUsernameSheet();

  @override
  State<_ChangeUsernameSheet> createState() => _ChangeUsernameSheetState();
}

class _ChangeUsernameSheetState extends State<_ChangeUsernameSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserBloc>().state.user;
    _controller = TextEditingController(text: user?.fullName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newName = _controller.text.trim();
    final user = context.read<UserBloc>().state.user;
    if (user == null) return;

    if (newName == user.fullName) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);
    final ok = await context.read<UserRepository>().updateFullName(newName);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      AppSnackBar.success(context, 'Username updated!');
      Navigator.of(context).pop();
    } else {
      AppSnackBar.error(context, 'Could not update. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Username',
              style: AppTextStyles.bold.copyWith(fontSize: 20),
            ),
            Space.vertical(6),
            Text(
              'Your name appears on your posts, comments, and replies.',
              style:
                  AppTextStyles.normal.copyWith(color: textSecondary, fontSize: 13),
            ),
            Space.vertical(20),
            CustomTextField(
              controller: _controller,
              hintText: 'Your name',
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'Please enter your name';
                if (v.length < 2) return 'Name must be at least 2 characters';
                if (v.length > 50) return 'Name is too long';
                return null;
              },
            ),
            Space.vertical(20),
            _SheetPrimaryButton(
              label: 'Save',
              loading: _saving,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Change-password sheet
//
// Re-authenticates with the current password before calling Firebase Auth's
// updatePassword. Maps the most common errors to friendly messages so the
// user knows what to fix without us dumping raw exception text.
// ─────────────────────────────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _saving = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await context.read<FirebaseAuthRepository>().updatePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (!mounted) return;
      AppSnackBar.success(context, 'Password updated!');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, _friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('wrong-password') ||
        msg.contains('invalid-credential')) {
      return 'Current password is incorrect.';
    }
    if (msg.contains('weak-password')) {
      return 'New password is too weak. Use at least 6 characters.';
    }
    if (msg.contains('requires-recent-login')) {
      return 'Please sign out and back in, then try again.';
    }
    return 'Could not change password. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Password',
              style: AppTextStyles.bold.copyWith(fontSize: 20),
            ),
            Space.vertical(6),
            Text(
              'Enter your current password to confirm, then choose a new one.',
              style:
                  AppTextStyles.normal.copyWith(color: textSecondary, fontSize: 13),
            ),
            Space.vertical(20),
            CustomTextField(
              controller: _currentCtrl,
              hintText: 'Current password',
              obscureText: !_showCurrent,
              suffix: _eyeToggle(
                visible: _showCurrent,
                onTap: () => setState(() => _showCurrent = !_showCurrent),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            Space.vertical(12),
            CustomTextField(
              controller: _newCtrl,
              hintText: 'New password',
              obscureText: !_showNew,
              suffix: _eyeToggle(
                visible: _showNew,
                onTap: () => setState(() => _showNew = !_showNew),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 6) return 'At least 6 characters';
                if (v == _currentCtrl.text) {
                  return 'Must differ from your current password';
                }
                return null;
              },
            ),
            Space.vertical(12),
            CustomTextField(
              controller: _confirmCtrl,
              hintText: 'Confirm new password',
              obscureText: !_showConfirm,
              suffix: _eyeToggle(
                visible: _showConfirm,
                onTap: () => setState(() => _showConfirm = !_showConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v != _newCtrl.text) return 'Passwords don\'t match';
                return null;
              },
            ),
            Space.vertical(20),
            _SheetPrimaryButton(
              label: 'Update Password',
              loading: _saving,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _eyeToggle({required bool visible, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: 20,
        color: textSecondary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete-account sheet
//
// Walks the user through the destructive flow:
//   1. Re-authenticates with the current password (Firebase requirement).
//   2. Cleans up Firestore data while still authenticated.
//   3. Deletes the Firebase Auth account.
//   4. Resets the local UserBloc + navigates to login.
//
// A red banner up top makes the consequences plain — once submitted, the
// account and every habit, completion, post, and comment authored by the
// user are gone for good.
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  bool _deleting = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_deleting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authRepo = context.read<FirebaseAuthRepository>();
    final userRepo = context.read<UserRepository>();
    final userBloc = context.read<UserBloc>();
    final router = GoRouter.of(context);

    setState(() => _deleting = true);
    try {
      // 1) Recent-login check.
      await authRepo.reauthenticate(_passwordCtrl.text);

      // 2) Wipe Firestore data while we still have an auth context.
      await userRepo.deleteAllUserData();

      // 3) Burn the auth account itself.
      await authRepo.deleteAccount();

      if (!mounted) return;

      // 4) Reset local state + leave the screen.
      Navigator.of(context).pop(); // close sheet
      userBloc.add(LogoutRequested());
      router.go(AppRoute.login.path);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, _friendlyError(e));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Password is incorrect.';
    }
    if (msg.contains('requires-recent-login')) {
      return 'Please sign out and back in, then try again.';
    }
    if (msg.contains('network')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Could not delete account. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Warning banner ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: red.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: red, size: 22),
                  Space.horizontal(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This cannot be undone',
                          style: AppTextStyles.semiBold
                              .copyWith(fontSize: 14, color: red),
                        ),
                        Space.vertical(4),
                        Text(
                          'Your habits, completion history, posts, comments, '
                          'and replies will be permanently deleted.',
                          style: AppTextStyles.normal.copyWith(
                            fontSize: 12,
                            color: textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Space.vertical(20),

            Text(
              'Confirm with your password',
              style: AppTextStyles.semiBold.copyWith(fontSize: 14),
            ),
            Space.vertical(10),
            CustomTextField(
              controller: _passwordCtrl,
              hintText: 'Current password',
              obscureText: !_showPassword,
              suffix: GestureDetector(
                onTap: () => setState(() => _showPassword = !_showPassword),
                child: Icon(
                  _showPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                  color: textSecondary,
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            Space.vertical(20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _deleting ? null : _delete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: red,
                  disabledBackgroundColor: red.withValues(alpha: 0.5),
                  foregroundColor: kWhiteColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _deleting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: kWhiteColor,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Delete My Account',
                        style: AppTextStyles.semiBold.copyWith(
                          fontSize: 15,
                          color: kWhiteColor,
                        ),
                      ),
              ),
            ),
            Space.vertical(8),
            Center(
              child: TextButton(
                onPressed: _deleting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.medium
                      .copyWith(color: textSecondary, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sheet button
// ─────────────────────────────────────────────────────────────────────────────

class _SheetPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _SheetPrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          disabledBackgroundColor: purple.withValues(alpha: 0.5),
          foregroundColor: kWhiteColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: kWhiteColor,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.semiBold.copyWith(
                  fontSize: 15,
                  color: kWhiteColor,
                ),
              ),
      ),
    );
  }
}
