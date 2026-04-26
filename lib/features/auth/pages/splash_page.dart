import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/navigation/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkUserAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryColor, kWhiteColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(child: SvgPicture.asset(Assets.svgSplashLogo)),
      ),
    );
  }

  void _checkUserAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final firebaseUser = context
        .read<UserBloc>()
        .firebaseAuthRepository
        .firebaseUser;
    if (firebaseUser != null) {
      context.go(AppRoute.bottomNavBar.path);
      return;
    }

    context.go(AppRoute.bottomNavBar.path);
  }
}
