import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'routes/app_routes.dart';

class FaculdadeApp extends StatelessWidget {
  const FaculdadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projeto Semestral',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
