import 'package:flutter/material.dart';

import '/core/auth/auth_guard.dart';
import '/core/auth/technical_role_guard.dart';

import '/features/home/presentation/pages/login_screen.dart';
import '/features/home/presentation/pages/home_page.dart';
import '/features/home/presentation/pages/technical_dashboard_page.dart';
import '/features/home/presentation/widgets/admin_layout.dart';
import '/features/home/presentation/widgets/technical_navigation.dart';

import '/features/demands/presentation/pages/demand_details_page.dart';
import '/features/demands/presentation/pages/demand_list_page.dart';
import '/features/demands/data/models/pedido_model.dart';
import '/features/demands/presentation/pages/technical_demand_list_page.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String demandDetails = '/demand-details';
  static const String demandList = '/demand-list';

  static final Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginScreen(),

    home: (_) => const AuthGuard(child: HomePage()),

    demandList: (_) => const AuthGuard(child: DemandListPage()),

    demandDetails: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;

      if (arguments is PedidoModel) {
        return AuthGuard(
          child: DemandDetailsPage(demandId: arguments.id, pedido: arguments),
        );
      }

      if (arguments is String) {
        return AuthGuard(child: DemandDetailsPage(demandId: arguments));
      }

      return const AuthGuard(
        child: Scaffold(
          body: Center(child: Text('Nenhuma demanda foi selecionada.')),
        ),
      );
    },

    TechnicalRoutes.home: (_) => const TechnicalRoleGuard(
      child: AdminLayout(child: TechnicalDashboardPage()),
    ),

    TechnicalRoutes.demandList: (_) => const TechnicalRoleGuard(
      child: AdminLayout(child: TechnicalDemandListPage()),
    ),
  };
}
