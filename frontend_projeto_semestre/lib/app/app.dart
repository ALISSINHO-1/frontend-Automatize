import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import '../features/home/presentation/widgets/admin_navigation_controller.dart';
import '../features/home/presentation/widgets/admin_layout.dart';

final adminNavigationController = AdminNavigationController();
final adminRouteObserver = AdminRouteObserver(adminNavigationController);
final GlobalKey<NavigatorState> adminNavigatorKey =
    GlobalKey<NavigatorState>();

class FaculdadeApp extends StatelessWidget {
  const FaculdadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  title: 'Projeto Semestral',
  debugShowCheckedModeBanner: false,
  theme: AppTheme.dark,
  initialRoute: AppRoutes.home,
  routes: AppRoutes.routes,
  navigatorKey: adminNavigatorKey,
  navigatorObservers: [adminRouteObserver],
  builder: (context, child) {
    return AdminLayout(
      child: child ?? const SizedBox.shrink(),
    );
  },
);
  }
}