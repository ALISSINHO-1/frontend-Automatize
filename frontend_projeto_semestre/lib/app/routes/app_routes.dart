import 'package:flutter/material.dart';

import '../../features/home/presentation/pages/home_page.dart';

abstract final class AppRoutes {
  static const String home = '/';

  static final Map<String, WidgetBuilder> routes = {
    home: (_) => const HomePage(),
  };
}
