import 'package:flutter/material.dart';

import '/core/auth/auth_guard.dart';
import '/core/auth/cliente_guard.dart';

import '/features/admin/presentation/pages/admin_panel_page.dart';
import '/features/admin/presentation/widgets/admin_guard.dart';

import '/features/home/presentation/pages/login_screen.dart';
import '/features/home/presentation/pages/home_page.dart';

import '/features/demands/presentation/pages/demand_details_page.dart';
import '/features/demands/presentation/pages/demand_list_page.dart';
import '/features/demands/data/models/pedido_model.dart';

/// Centraliza as rotas utilizadas pelo Automatize.
///
/// SCRUM-116:
/// - Rotas públicas: acesso sem autenticação.
/// - Rotas CLIENTE: exigem sessão e perfil CLIENTE.
/// - Rotas ADMIN: exigem sessão e perfil ADMIN.
///
/// A autorização definitiva dos dados é feita pela API.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String demandDetails = '/demand-details';
  static const String demandList = '/demand-list';
  static const String admin = '/admin';

  static final Map<String, WidgetBuilder> routes = {
    // ROTA PÚBLICA
    // Login disponível para usuários não autenticados.
    login: (_) => const LoginScreen(),

    // PORTAL CLIENTE
    // Exige token válido e perfil CLIENTE.
    home: (_) => const AuthGuard(child: ClienteGuard(child: HomePage())),

    // PORTAL ADMINISTRATIVO
    // Exige autenticação e perfil ADMIN.
    // Mantém o AdminGuard já implementado pela equipe.
    admin: (_) => const AuthGuard(child: AdminGuard(child: AdminPanelPage())),

    // LISTAGEM DE DEMANDAS DO CLIENTE
    // Bloqueia o acesso de outros perfis.
    demandList: (_) =>
        const AuthGuard(child: ClienteGuard(child: DemandListPage())),

    // DETALHES DA DEMANDA
    // Exige autenticação e perfil CLIENTE.
    demandDetails: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;

      // Navegação com o objeto completo da demanda.
      if (arguments is PedidoModel) {
        return AuthGuard(
          child: ClienteGuard(
            child: DemandDetailsPage(demandId: arguments.id, pedido: arguments),
          ),
        );
      }

      // Navegação informando apenas o ID da demanda.
      if (arguments is String) {
        return AuthGuard(
          child: ClienteGuard(child: DemandDetailsPage(demandId: arguments)),
        );
      }

      // Nenhuma demanda foi informada.
      return const AuthGuard(
        child: ClienteGuard(
          child: Scaffold(
            body: Center(child: Text('Nenhuma demanda foi selecionada.')),
          ),
        ),
      );
    },
  };
}
