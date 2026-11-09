
import 'package:flutter/material.dart';

class AdminNavigationController extends ChangeNotifier {
  String _currentRoute = '/';

  String get currentRoute => _currentRoute;

  void setRoute(String route) {
    if (_currentRoute == route) return;

    _currentRoute = route;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}

class AdminRouteObserver extends NavigatorObserver {
  final AdminNavigationController controller;

  AdminRouteObserver(this.controller);

  String _identificarRota(Route<dynamic>? route) {
    if (route == null) return '/';

    final nome = route.settings.name;

    if (nome != null && nome.isNotEmpty) {
      return nome;
    }

    // Rotas internas abertas com MaterialPageRoute
    // sem um nome explícito.
    return '/pagina-interna';
  }

  void _atualizarRota(Route<dynamic>? route) {
    controller.setRoute(_identificarRota(route));
  }

  @override
  void didPush(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    _atualizarRota(route);
  }

  @override
  void didPop(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    _atualizarRota(previousRoute);
  }

  @override
  void didReplace({
    Route<dynamic>? newRoute,
    Route<dynamic>? oldRoute,
  }) {
    _atualizarRota(newRoute);
  }

  @override
  void didRemove(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    // Não alteramos a rota ativa aqui, pois a rota
    // removida pode não ser a que está sendo exibida.
  }
}
