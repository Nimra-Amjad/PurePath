import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AppRoute {
  splash('/splash'),
  home('/home'),
  preferences('/preferences'),
  login('/login'),
  signup('/signup');

  const AppRoute(this.path);

  final String path;
}

extension AppRouteNavigation on AppRoute {
  void go(BuildContext context) => context.go(path);

  Future push(BuildContext context, {Object? extra}) async =>
      context.push(path, extra: extra);

  Future pushReplacement(BuildContext context, {Object? extra}) async =>
      context.pushReplacement(path, extra: extra);

  bool canPop(BuildContext context) => GoRouter.of(context).canPop();
}
