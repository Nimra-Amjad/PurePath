import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/notifications/bloc/notification_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reminders page
//
// One master switch that mirrors `user.notificationsEnabled`. Flipping it
// dispatches [NotificationToggled] — the bloc handles persistence and OS
// schedule sync. The page stays purely presentational.
// ─────────────────────────────────────────────────────────────────────────────

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(context),
      body: BlocListener<NotificationBloc, NotificationState>(
        listenWhen: (a, b) =>
            a.errorMessage != b.errorMessage && b.errorMessage != null,
        listener: (context, state) {
          AppSnackBar.error(context, state.errorMessage!);
        },
        child: BlocBuilder<UserBloc, UserState>(
          buildWhen: (a, b) =>
              a.user?.notificationsEnabled != b.user?.notificationsEnabled,
          builder: (context, state) {
            final enabled = state.user?.notificationsEnabled ?? false;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ToggleCard(
                  isEnabled: enabled,
                  onChanged: (value) => context
                      .read<NotificationBloc>()
                      .add(NotificationToggled(enabled: value)),
                ),
                Space.vertical(16),
                _InfoCard(enabled: enabled),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: kWhiteColor,
      surfaceTintColor: kWhiteColor,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: kBlackColor.withOpacityValue(0.06),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: kBlackColor,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Reminders',
        style: AppTextStyles.bold.copyWith(fontSize: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Master toggle card
// ─────────────────────────────────────────────────────────────────────────────

class _ToggleCard extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({required this.isEnabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isEnabled ? lightPurple : kLightGreyColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _icon(),
          Space.horizontal(14),
          Expanded(child: _labels()),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeThumbColor: purple,
            activeTrackColor: lightPurple,
          ),
        ],
      ),
    );
  }

  Widget _icon() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isEnabled
            ? purple.withOpacityValue(0.18)
            : kGreyColor.withOpacityValue(0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isEnabled
            ? Icons.notifications_active_rounded
            : Icons.notifications_off_rounded,
        color: isEnabled ? purple : textSecondary,
        size: 22,
      ),
    );
  }

  Widget _labels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Habit Reminders',
          style: AppTextStyles.semiBold.copyWith(fontSize: 15),
        ),
        Space.vertical(2),
        Text(
          isEnabled ? "You'll get a daily nudge" : 'Reminders are off',
          style: AppTextStyles.normal.copyWith(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper / explanatory card
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final bool enabled;
  const _InfoCard({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          Space.horizontal(10),
          Expanded(
            child: Text(
              enabled
                  ? "We'll remind you to check off your habits so your "
                      'streak stays alive.'
                  : "Turn reminders on and we'll send you a friendly nudge "
                      'so you never miss a day.',
              style: AppTextStyles.normal.copyWith(
                fontSize: 12,
                color: textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
