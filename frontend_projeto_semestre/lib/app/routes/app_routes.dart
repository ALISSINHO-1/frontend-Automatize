import 'package:flutter/material.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/demands/presentation/pages/demand_details_page.dart';
import '../../features/demands/data/models/pedido_model.dart';
import '../../features/demands/presentation/pages/demand_list_page.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String demandDetails = '/demand-details';
  static const String demandList = '/demand-list';

  static final Map<String, WidgetBuilder> routes = {
    demandList: (_) => const DemandListPage(),
  home: (_) => const HomePage(),
  demandDetails: (context) {
  final arguments = ModalRoute.of(context)?.settings.arguments;

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
    child: Text('Nenhuma demanda foi selecionada.'),
  ),
);
},
  };
}