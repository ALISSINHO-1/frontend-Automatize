import 'package:flutter/material.dart';

import '/core/auth/auth_guard.dart';
import '/core/auth/cliente_guard.dart';

import '/features/admin/presentation/pages/admin_panel_page.dart';
import '/features/admin/presentation/widgets/admin_guard.dart';

import '/features/home/presentation/pages/login_screen.dart';
import '/features/home/presentation/pages/home_page.dart';

import '/features/demands/data/models/pedido_model.dart';
import '/features/demands/presentation/pages/cliente_demanda_detalhes_page.dart';
import '/features/demands/presentation/pages/cliente_ocorrencias_page.dart';
import '/features/demands/presentation/pages/demand_details_page.dart';
import '/features/demands/presentation/pages/demand_homologation_page.dart';
import '/features/demands/presentation/pages/demand_list_page.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String demandDetails = '/demand-details';
  static const String demandList = '/demand-list';
  static const String admin = '/admin';

  static const String clienteDetalhes = '/cliente/demandas/detalhes';

  static const String clienteHomologacao = '/cliente/demandas/homologacao';

  static const String clienteOcorrencias = '/cliente/demandas/ocorrencias';

  static final Map<String, WidgetBuilder> routes = {
    // Rota pública: login.
    login: (_) => const LoginScreen(),

    // Portal do CLIENTE.
    home: (_) => const AuthGuard(child: ClienteGuard(child: HomePage())),

    // Portal administrativo.
    admin: (_) => const AuthGuard(child: AdminGuard(child: AdminPanelPage())),

    // Lista de demandas do CLIENTE.
    demandList: (_) =>
        const AuthGuard(child: ClienteGuard(child: DemandListPage())),

    // Rota antiga de detalhes, preservada.
    demandDetails: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;

      if (arguments is PedidoModel) {
        return AuthGuard(
          child: ClienteGuard(
            child: DemandDetailsPage(demandId: arguments.id, pedido: arguments),
          ),
        );
      }

      if (arguments is String && arguments.trim().isNotEmpty) {
        return AuthGuard(
          child: ClienteGuard(child: DemandDetailsPage(demandId: arguments)),
        );
      }

      return const AuthGuard(
        child: ClienteGuard(
          child: Scaffold(
            body: Center(child: Text('Nenhuma demanda foi selecionada.')),
          ),
        ),
      );
    },

    clienteDetalhes: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;

      return AuthGuard(
        child: ClienteGuard(
          child: arguments is String && arguments.trim().isNotEmpty
              ? ClienteDemandaDetalhesPage(demandaId: arguments)
              : const Scaffold(
                  body: Center(child: Text('Demanda não selecionada.')),
                ),
        ),
      );
    },

    clienteHomologacao: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;

      return AuthGuard(
        child: ClienteGuard(
          child: arguments is PedidoModel
              ? DemandHomologationPage(pedido: arguments)
              : const Scaffold(
                  body: Center(child: Text('Demanda não selecionada.')),
                ),
        ),
      );
    },

    clienteOcorrencias: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;

      return AuthGuard(
        child: ClienteGuard(
          child: arguments is String && arguments.trim().isNotEmpty
              ? ClienteOcorrenciasPage(demandaId: arguments)
              : const Scaffold(
                  body: Center(child: Text('Demanda não selecionada.')),
                ),
        ),
      );
    },
  };
}
