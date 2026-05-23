import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/app/pure_path_app.dart';
import 'package:purepath/core/extensions/print_log.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/features/auth/pages/login_page.dart';
import 'package:purepath/features/auth/pages/signup_page.dart';
import 'package:purepath/features/auth/pages/splash_page.dart';
import 'package:purepath/features/bottom_nav_bar/bottom_nav_bar_page.dart';
import 'package:purepath/features/community/models/post_model.dart';
import 'package:purepath/features/community/pages/post_detail_page.dart';
import 'package:purepath/features/home/models/habit_definition.dart';
import 'package:purepath/features/home/pages/add_habit_page.dart';
import 'package:purepath/features/home/pages/edit_habit_page.dart';
import 'package:purepath/features/home/pages/habits_page.dart';
import 'package:purepath/features/preferences/pages/preferences_page.dart';
import 'package:purepath/features/preferences/pages/welcome_page.dart';
import 'package:purepath/features/preferences/views/summary_page.dart';
import 'package:purepath/features/profile/pages/badges_page.dart';
import 'package:purepath/features/profile/pages/reminders_page.dart';

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
      pageBuilder: (context, state) => _fadePage(state, const SplashPage()),
    ),
    GoRoute(
      path: AppRoute.login.path,
      pageBuilder: (context, state) => _fadePage(state, const LoginPage()),
    ),
    GoRoute(
      path: AppRoute.signup.path,
      pageBuilder: (context, state) => _fadePage(state, const SignupPage()),
    ),
    GoRoute(
      path: AppRoute.preferences.path,
      pageBuilder: (context, state) =>
          _fadePage(state, const PreferencesPage()),
    ),
    GoRoute(
      path: AppRoute.welcome.path,
      pageBuilder: (context, state) => _fadePage(state, const WelcomePage()),
    ),
    GoRoute(
      path: AppRoute.summary.path,
      pageBuilder: (context, state) => _fadePage(state, const SummaryPage()),
    ),
    GoRoute(
      path: AppRoute.bottomNavBar.path,
      pageBuilder: (context, state) =>
          _fadePage(state, const BottomNavBarPage()),
    ),
    GoRoute(
      path: AppRoute.addHabit.path,
      pageBuilder: (context, state) => _fadePage(state, const AddHabitPage()),
    ),
    GoRoute(
      path: AppRoute.habits.path,
      pageBuilder: (context, state) => _fadePage(state, const HabitsPage()),
    ),
    GoRoute(
      path: AppRoute.editHabit.path,
      pageBuilder: (context, state) => _fadePage(
        state,
        EditHabitPage(habit: state.extra as HabitDefinition),
      ),
    ),
    GoRoute(
      path: AppRoute.badges.path,
      pageBuilder: (context, state) => _fadePage(state, const BadgesPage()),
    ),
    GoRoute(
      path: AppRoute.reminders.path,
      pageBuilder: (context, state) => _fadePage(state, const RemindersPage()),
    ),
    GoRoute(
      path: AppRoute.postDetail.path,
      pageBuilder: (context, state) =>
          _fadePage(state, PostDetailPage(post: state.extra as PostModel)),
    ),
  ],
);

CustomTransitionPage<T> _fadePage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

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
