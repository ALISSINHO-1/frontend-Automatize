import 'package:flutter/foundation.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../models/usuario_atual_model.dart';
import 'admin_demand_service.dart';

/// Guarda o resultado de `GET /auth/me` da sessão atual.
///
/// O cache é amarrado ao token: depois de logout/novo login (token diferente)
/// o perfil é consultado de novo, então um cliente nunca herda o menu de um admin.
class UsuarioAtualStore extends ValueNotifier<UsuarioAtualModel?> {
  UsuarioAtualStore._() : super(null);

  static final UsuarioAtualStore instance = UsuarioAtualStore._();

  String? _tokenDoCache;
  Future<UsuarioAtualModel?>? _emAndamento;

  /// Permite injetar um serviço falso nos testes.
  AdminDemandService Function() criarServico = AdminDemandService.new;

  Future<UsuarioAtualModel?> carregar() async {
    final token = await LocalStorageService.getToken();
    if (token == null || token.isEmpty) {
      _limpar();
      return null;
    }
    if (token == _tokenDoCache && value != null) return value;
    if (token == _tokenDoCache && _emAndamento != null) return _emAndamento;

    _tokenDoCache = token;
    value = null;
    return _emAndamento = _buscar(token);
  }

  Future<UsuarioAtualModel?> _buscar(String token) async {
    final servico = criarServico();
    try {
      final usuario = await servico.usuarioAtual();
      // Ignora a resposta se a sessão mudou enquanto a requisição estava no ar.
      if (await LocalStorageService.getToken() == token) value = usuario;
      return usuario;
    } finally {
      _emAndamento = null;
      servico.dispose();
    }
  }

  void _limpar() {
    _tokenDoCache = null;
    _emAndamento = null;
    value = null;
  }

  @visibleForTesting
  void reiniciar() {
    _limpar();
    criarServico = AdminDemandService.new;
  }
}
