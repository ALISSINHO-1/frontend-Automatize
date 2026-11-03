
import 'package:flutter/material.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/demands/presentation/pages/demand_details_page.dart';
import '../../features/demands/presentation/pages/demand_history_page.dart';
import '../../features/demands/presentation/pages/demand_attachments_hub_page.dart';
import '../../features/demands/data/models/pedido_model.dart';
import '../../features/demands/presentation/pages/demand_list_page.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String demandDetails = '/demand-details';
  static const String demandList = '/demand-list';
  static const String demandHistory = '/demand-history';
  static const String demandAttachments = '/demand-attachments';

  static final Map<String, WidgetBuilder> routes = {
    home: (_) => const HomePage(),

    demandList: (_) => const DemandListPage(),

    demandHistory: (_) => const DemandHistoryPage(),

    demandAttachments: (_) => const DemandAttachmentsHubPage(),

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
