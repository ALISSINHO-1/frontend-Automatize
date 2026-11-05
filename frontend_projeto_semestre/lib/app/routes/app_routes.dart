import 'package:flutter/material.dart';
import '/core/auth/auth_guard.dart';
import '/features/admin/presentation/pages/admin_panel_page.dart';
import '/features/admin/presentation/widgets/admin_guard.dart';
import '/features/home/presentation/pages/login_screen.dart';
import '/features/home/presentation/pages/home_page.dart';
import '/features/demands/presentation/pages/demand_details_page.dart';
import '/features/demands/presentation/pages/demand_list_page.dart';
import '/features/demands/data/models/pedido_model.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String demandDetails = '/demand-details';
  static const String demandList = '/demand-list';
  static const String admin = '/admin';

  static final Map<String, WidgetBuilder> routes = {
    // Rota pública: login.
    login: (_) => const LoginScreen(),

    // Rota protegida: Home do cliente.
    home: (_) => const AuthGuard(child: HomePage()),

    // Rota protegida: exige sessão e perfil ADMIN (GET /auth/me).
    admin: (_) => const AuthGuard(child: AdminGuard(child: AdminPanelPage())),

    // Rota protegida: lista de demandas.
    demandList: (_) => const AuthGuard(child: DemandListPage()),

    // Rota protegida: detalhes da demanda.
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
  };
}
