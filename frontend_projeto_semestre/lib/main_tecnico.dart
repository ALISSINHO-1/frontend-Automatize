import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/technical_dashboard_page.dart';
import 'features/home/presentation/widgets/admin_layout.dart';
import 'features/demands/presentation/pages/technical_demand_list_page.dart';
import 'features/demands/presentation/pages/demand_history_page.dart';
import 'features/demands/presentation/pages/demand_attachments_hub_page.dart';
import 'features/home/presentation/widgets/technical_navigation.dart';

void main() {
  runApp(const AutomatizeTecnicoApp());
}

class AutomatizeTecnicoApp extends StatelessWidget {
  const AutomatizeTecnicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AUTOMATIZE | Painel Técnico',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      navigatorKey: adminNavigatorKey,
      navigatorObservers: [adminRouteObserver],
      initialRoute: TechnicalRoutes.home,
      routes: {
        TechnicalRoutes.home: (_) => const AdminLayout(
          child: TechnicalDashboardPage(),
        ),
        TechnicalRoutes.demandList: (_) => const AdminLayout(
          child: TechnicalDemandListPage(),
        ),
        TechnicalRoutes.demandHistory: (_) => const AdminLayout(
          child: DemandHistoryPage(),
        ),
        TechnicalRoutes.demandAttachments: (_) => const AdminLayout(
          child: DemandAttachmentsHubPage(),
        ),
      },
    );
  }
}
