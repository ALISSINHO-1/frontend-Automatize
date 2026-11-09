import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'routes/app_routes.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class FaculdadeApp extends StatelessWidget {
  const FaculdadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projeto Semestral',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.dark,

      navigatorKey: appNavigatorKey,

      routes: AppRoutes.routes,
    );
  }
}
