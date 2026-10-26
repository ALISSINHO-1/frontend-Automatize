import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/home/data/auth_service.dart';
import '../features/home/presentation/pages/login_screen.dart';
import 'routes/app_routes.dart';

class FaculdadeApp extends StatefulWidget {
  const FaculdadeApp({super.key});

  @override
  State<FaculdadeApp> createState() => _FaculdadeAppState();
}

class _FaculdadeAppState extends State<FaculdadeApp> {
  final AuthService _authService = AuthService();

  Future<void> _login(BuildContext context, String email, String senha) async {
    await _authService.login(email, senha);
    if (!mounted || !context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automatize',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.home,
      routes: {
        for (final route in AppRoutes.routes.entries)
          route.key: (context) {
            if (AuthService.accessToken == null) {
              return LoginScreen(
                onLogin: (email, senha) => _login(context, email, senha),
              );
            }
            return route.value(context);
          },
      },
    );
  }
}
