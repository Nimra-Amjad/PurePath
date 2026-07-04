import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/app/pure_path_app.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/app_constants.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/models/app_version_config.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/repositories/app_version_repository.dart';
import 'package:purepath/core/widgets/app_update_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SplashPage
//
// Shown for ~2 s while we check whether a Firebase session already exists.
// Dispatches [LoadUser] to UserBloc and listens for the result:
//
//   UserSessionRestored  → go to home (onboarding already completed)
//   UserOnboardingIncomplete → go to preferences (resume onboarding)
//   UserNotFound         → go to login
//
// The splash also fetches the `appVersionConfig` from Firestore. When the
// installed [kBuildNo] is behind the remote one, the update sheet is shown on
// top of whichever view we just navigated to (via the root navigator, since
// this page is disposed after `context.go`).
// ─────────────────────────────────────────────────────────────────────────────

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  AppVersionConfig? _versionConfig;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  void _checkSession() async {
    _versionConfig = await context.read<AppVersionRepository>().fetchConfig();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final bloc = context.read<UserBloc>();
    final firebaseUser = bloc.firebaseAuthRepository.firebaseUser;
    bloc.add(LoadUser(firebaseUser));
  }

  /// Opens the update sheet on top of the view we just navigated to. Uses the
  /// root navigator context because this splash page is disposed by then.
  void _showUpdateSheetIfNeeded() {
    final config = _versionConfig;
    if (config == null || config.buildNo <= kBuildNo) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = PurePathApp.navigatorKey.currentContext;
      if (context == null) return;
      AppUpdateSheet.show(context, forceUpdate: config.forceUpdate);
    });
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
        } else {
          return;
        }
        _showUpdateSheetIfNeeded();
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
