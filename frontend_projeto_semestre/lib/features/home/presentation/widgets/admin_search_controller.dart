
import 'package:flutter/foundation.dart';

class AdminSearchController extends ChangeNotifier {
  String _query = '';

  String get query => _query;

  void atualizarBusca(String valor) {
    if (_query == valor) return;

    _query = valor;
    notifyListeners();
  }

  void limparBusca() {
    atualizarBusca('');
  }
}

final adminSearchController = AdminSearchController();
