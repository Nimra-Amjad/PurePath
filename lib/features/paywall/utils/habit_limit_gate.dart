import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/constants/app_constants.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/repositories/home_repository.dart';
import 'package:purepath/features/paywall/bloc/subscription_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit limit gate
//
// Free users can keep up to [kFreeHabitLimit] habits; Pro users are
// unlimited. Every entry point that creates a habit goes through this gate so
// the rule lives in exactly one place.
// ─────────────────────────────────────────────────────────────────────────────

/// Opens the add-habit form, or the paywall when the free limit is reached.
Future<void> openAddHabitGated(BuildContext context) async {
  if (await canAddHabit(context) && context.mounted) {
    AppRoute.addHabit.push(context);
  }
}

/// Returns whether the user may add another habit right now. When the free
/// limit is reached this opens the paywall and returns false.
Future<bool> canAddHabit(BuildContext context) async {
  if (context.read<SubscriptionBloc>().state.isPro) return true;

  final habits = await context.read<HomeRepository>().getAllHabits();
  if (habits.length < kFreeHabitLimit) return true;

  if (context.mounted) AppRoute.paywall.push(context);
  return false;
}
