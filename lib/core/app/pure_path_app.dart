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
      child: MaterialApp.router(
        key: const Key('material_app_key'),
        title: "PurePath",
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }
}
