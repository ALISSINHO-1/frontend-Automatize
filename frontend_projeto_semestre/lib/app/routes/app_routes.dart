import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/login_screen.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/demands/presentation/pages/demand_details_page.dart';
import '../../features/demands/presentation/pages/demand_list_page.dart';
import '../../features/demands/data/models/pedido_model.dart';

abstract final class AppRoutes {

  // Rotas do cliente.
  static const String login = '/login';
  static const String home = '/home';
  static const String demandDetails = '/demand-details';
  static const String demandList = '/demand-list';

  static final Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginScreen(),

    home: (_) => const HomePage(),

    demandList: (_) => const DemandListPage(),

    demandDetails: (context) {
      final arguments =
          ModalRoute.of(context)?.settings.arguments;

      if (arguments is PedidoModel) {
        return DemandDetailsPage(
          demandId: arguments.id,
          pedido: arguments,
        );
      }

      if (arguments is String) {
        return DemandDetailsPage(
          demandId: arguments,
        );
      }

      return const Scaffold(
        body: Center(
          child: Text(
            'Nenhuma demanda foi selecionada.',
          ),
        ),
      );
    },
  };
}
