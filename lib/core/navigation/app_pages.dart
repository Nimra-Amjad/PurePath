import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/app/pure_path_app.dart';
import 'package:purepath/core/extensions/print_log.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/features/auth/pages/login_page.dart';
import 'package:purepath/features/auth/pages/signup_page.dart';
import 'package:purepath/features/auth/pages/splash_page.dart';
import 'package:purepath/features/onboarding/pages/onboarding_page.dart';

final router = GoRouter(
  debugLogDiagnostics: kDebugMode,
  initialLocation: AppRoute.splash.path,
  restorationScopeId: 'root',
  navigatorKey: PurePathApp.navigatorKey,
  observers: <NavigatorObserver>[AppRouteObserver()],
  errorBuilder: (context, state) => const SplashPage(),
  routes: [
    GoRoute(
      path: AppRoute.splash.path,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoute.login.path,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoute.signup.path,
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: AppRoute.onboarding.path,
      builder: (context, state) => const OnboardingPage(),
    ),
  ],
);

class AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    'New route pushed: ${route.settings.name}'.printInfo();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    'Route popped: ${route.settings.name}'.printInfo();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    'Route replaced: ${newRoute?.settings.name}'.printInfo();
  }
}
