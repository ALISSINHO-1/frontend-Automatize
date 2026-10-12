import 'package:flutter/material.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/demands/presentation/pages/demand_details_page.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String demandDetails = '/demand-details';

  static final Map<String, WidgetBuilder> routes = {
    home: (_) => const HomePage(),
    demandDetails: (_) => const DemandDetailsPage(),
  };
}