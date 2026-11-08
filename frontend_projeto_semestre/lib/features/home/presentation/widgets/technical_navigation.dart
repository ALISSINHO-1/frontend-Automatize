import 'package:flutter/material.dart';

import 'admin_navigation_controller.dart';

final adminNavigationController = AdminNavigationController();
final adminRouteObserver = AdminRouteObserver(adminNavigationController);

final GlobalKey<NavigatorState> adminNavigatorKey = GlobalKey<NavigatorState>();

abstract final class TechnicalRoutes {
  static const home = '/tecnico';
  static const demandList = '/tecnico/demandas';
  static const demandDetails = '/tecnico/demandas/detalhes';
  static const demandHistory = '/tecnico/historico';
  static const demandAttachments = '/tecnico/anexos';
}
