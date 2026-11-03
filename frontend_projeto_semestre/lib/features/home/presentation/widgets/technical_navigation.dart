import 'package:flutter/material.dart';
import 'admin_navigation_controller.dart';

final adminNavigationController = AdminNavigationController();
final adminRouteObserver = AdminRouteObserver(adminNavigationController);
final GlobalKey<NavigatorState> adminNavigatorKey =
    GlobalKey<NavigatorState>();

abstract final class TechnicalRoutes {
  static const home = '/';
  static const demandList = '/demand-list';
  static const demandDetails = '/demand-details';
  static const demandHistory = '/demand-history';
  static const demandAttachments = '/demand-attachments';
}
