import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (a, b) => a.user != b.user,
      builder: (context, state) {
        final firstName = state.user?.firstName.trim() ?? '';
        final displayName = firstName.isEmpty ? 'there' : firstName;
        // Streak is persisted on the user doc (the `streak` field).
        final streak = state.user?.streak ?? 0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: AppTextStyles.normal.copyWith(color: kWhiteColor),
                ),
                Space.vertical(2),
                Text(
                  displayName,
                  style: AppTextStyles.bold.copyWith(
                    fontSize: 20,
                    color: kWhiteColor,
                  ),
                ),
              ],
            ),
            _StreakChip(streak: streak),
          ],
        );
      },
    );
  }

  /// Time-of-day-aware greeting so the home header doesn't always say
  /// "Good Morning" at 9pm.
  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}

/// Compact streak counter shown at the top of the home screen: 🔥 + the
/// current consecutive-day streak.
class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 15)),
          Space.horizontal(6),
          Text(
            '$streak',
            style: AppTextStyles.bold.copyWith(
              fontSize: 15,
              color: kPrimaryGreenColor,
            ),
          ),
        ],
      ),
    );
  }
}
