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
        final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

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
            CircleAvatar(
              backgroundColor: kContainerColor,
              child: Text(
                initial,
                style: AppTextStyles.bold.copyWith(
                  fontSize: 20,
                  color: kWhiteColor,
                ),
              ),
            ),
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
