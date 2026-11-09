import 'package:flutter/material.dart';

import '/core/auth/auth_guard.dart';
import '/core/auth/cliente_guard.dart';

import '/features/admin/presentation/pages/admin_panel_page.dart';
import '/features/admin/presentation/widgets/admin_guard.dart';

import '/features/home/presentation/pages/login_screen.dart';
import '/features/home/presentation/pages/home_page.dart';

import '/features/demands/data/models/pedido_model.dart';
import '/features/demands/presentation/pages/cliente_demanda_detalhes_page.dart';
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

  static final Map<String, WidgetBuilder> routes = {
    // LOGIN: rota pública.
    login: (_) => const LoginScreen(),

    // CLIENTE: página principal.
    home: (_) => const AuthGuard(child: ClienteGuard(child: HomePage())),

    // ADMIN: painel administrativo.
    admin: (_) => const AuthGuard(child: AdminGuard(child: AdminPanelPage())),

    // CLIENTE: listagem de demandas.
    demandList: (_) =>
        const AuthGuard(child: ClienteGuard(child: DemandListPage())),

    // CLIENTE: página antiga de detalhes.
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

    // SCRUM-112: acompanhamento real da demanda.
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

    // SCRUM-113: homologação da entrega.
    //
    // A versão atual de DemandHomologationPage
    // exige um PedidoModel pelo parâmetro "pedido".
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
  };
}
