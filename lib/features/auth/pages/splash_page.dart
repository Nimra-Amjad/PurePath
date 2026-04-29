import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/navigation/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SplashPage
//
// Shown for ~2 s while we check whether a Firebase session already exists.
// Dispatches [LoadUser] to UserBloc and listens for the result:
//
//   UserSessionRestored  → go to home (onboarding already completed)
//   UserOnboardingIncomplete → go to preferences (resume onboarding)
//   UserNotFound         → go to login
// ─────────────────────────────────────────────────────────────────────────────

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  void _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final bloc = context.read<UserBloc>();
    final firebaseUser = bloc.firebaseAuthRepository.firebaseUser;
    bloc.add(LoadUser(firebaseUser));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UserSessionRestored) {
          context.go(AppRoute.bottomNavBar.path);
        } else if (state is UserOnboardingIncomplete) {
          context.go(AppRoute.preferences.path);
        } else if (state is UserNotFound) {
          context.go(AppRoute.login.path);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryColor, kWhiteColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(child: SvgPicture.asset(Assets.svgSplashLogo)),
        ),
      ),
    );
  }
}
