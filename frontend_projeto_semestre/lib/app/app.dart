import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/config/app_config.dart';
import '../features/home/presentation/widgets/technical_navigation.dart';
import 'routes/app_routes.dart';
import '../features/onboarding/presentation/pages/verificar_email_screen.dart';
import '../features/onboarding/presentation/pages/redefinir_senha_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class FaculdadeApp extends StatelessWidget {
  const FaculdadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.dark,

      navigatorKey: appNavigatorKey,
      navigatorObservers: [adminRouteObserver],

      routes: AppRoutes.routes,
      // Links de e-mail chegam com query string, diferente das rotas exatas.
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '');
        if (uri?.path == AppRoutes.verificarEmail) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => VerificarEmailScreen(token: uri?.queryParameters['token']),
          );
        }
        if (uri?.path == AppRoutes.redefinirSenha) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => RedefinirSenhaScreen(token: uri?.queryParameters['token']),
          );
        }
        return null;
      },
    );
  }
}
