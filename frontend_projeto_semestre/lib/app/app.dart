import 'package:flutter/material.dart';
import '../features/home/presentation/pages/login_screen.dart';
import '../core/theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

class FaculdadeApp extends StatelessWidget {
  const FaculdadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projeto Semestral',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: appNavigatorKey,
      home: const LoginScreen(),
    );
  }
}
