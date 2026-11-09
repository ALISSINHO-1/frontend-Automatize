
import 'package:flutter/foundation.dart';

import '../../features/home/data/current_user_service.dart';

class CurrentUserSession extends ChangeNotifier {
  CurrentUser? _user;

  CurrentUser? get user => _user;

  bool get isAuthenticated => _user != null;

  void setUser(CurrentUser user) {
    _user = user;
    notifyListeners();
  }

  void clear() {
    if (_user == null) return;

    _user = null;
    notifyListeners();
  }

  String get displayName {
    final nome = _user?.nome?.trim();

    if (nome != null && nome.isNotEmpty) {
      return nome;
    }

    final email = _user?.email?.trim();

    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'Técnico';
  }

  String get initials {
    final nome = _user?.nome?.trim();

    if (nome != null && nome.isNotEmpty) {
      final partes = nome.split(RegExp(r'\s+'));

      if (partes.length >= 2) {
        return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
      }

      return partes.first.substring(
        0,
        partes.first.length >= 2 ? 2 : 1,
      ).toUpperCase();
    }

    return 'TC';
  }

  String get roleLabel {
    return switch (_user?.role) {
      CurrentUserRole.admin => 'Administrador',
      CurrentUserRole.tecnico => 'Técnico',
      CurrentUserRole.cliente => 'Cliente',
      null => 'Usuário',
    };
  }
}

final currentUserSession = CurrentUserSession();
