import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purepath/core/app/di.dart';
import 'package:purepath/core/navigation/app_pages.dart';

class PurePathApp extends StatefulWidget {
  const PurePathApp({super.key});
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<PurePathApp> createState() => _PurePathAppState();
}

class _PurePathAppState extends State<PurePathApp> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return DI(
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.noScaling, boldText: false),
        child: MaterialApp.router(
          key: const Key('material_app_key'),
          title: "PurePath",
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            // The app is dark-themed, so Cupertino widgets (e.g. the date and
            // time pickers) must render their text in white.
            cupertinoOverrideTheme: const CupertinoThemeData(
              brightness: Brightness.dark,
            ),
          ),
          routerConfig: router,
        ),
      ),
    );
  }
}
