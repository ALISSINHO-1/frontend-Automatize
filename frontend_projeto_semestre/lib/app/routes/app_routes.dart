import '../../features/home/data/auth_service.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String admin = '/admin';
  static const String tecnico = '/tecnico';
  static const String cliente = '/cliente';
  static const String demandDetails = '/demand-details';
  static const String demandList = '/demand-list';

  static String dashboardFor(UserRole role) => switch (role) {
    UserRole.admin => admin,
    UserRole.tecnico => tecnico,
    UserRole.cliente => cliente,
  };
}
