import 'package:flutter/foundation.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../models/usuario_atual_model.dart';
import 'admin_demand_service.dart';

/// Guarda o resultado de GET /auth/me da sessão atual.
///
/// O cache é vinculado ao token de autenticação.
/// Quando o usuário faz logout ou troca de conta,
/// os dados da sessão anterior não devem ser reutilizados.
class UsuarioAtualStore extends ValueNotifier<UsuarioAtualModel?> {
  UsuarioAtualStore._() : super(null);

  static final UsuarioAtualStore instance = UsuarioAtualStore._();

  String? _tokenDoCache;
  Future<UsuarioAtualModel?>? _emAndamento;

  /// Permite injetar um serviço falso nos testes.
  AdminDemandService Function() criarServico = AdminDemandService.new;

  /// Carrega o usuário autenticado a partir da API.
  Future<UsuarioAtualModel?> carregar() async {
    final token = await LocalStorageService.getToken();

    // Sem token, nenhuma informação anterior pode permanecer.
    if (token == null || token.isEmpty) {
      _limpar();
      return null;
    }

    // Reutiliza o usuário somente se pertencer ao token atual.
    if (token == _tokenDoCache && value != null) {
      return value;
    }

    // Evita requisições duplicadas para a mesma sessão.
    if (token == _tokenDoCache && _emAndamento != null) {
      return _emAndamento;
    }

    // Nova sessão: descarta os dados anteriores.
    _tokenDoCache = token;
    value = null;

    return _emAndamento = _buscar(token);
  }

  /// Busca o perfil real do usuário autenticado.
  Future<UsuarioAtualModel?> _buscar(String token) async {
    final servico = criarServico();

    try {
      final usuario = await servico.usuarioAtual();

      // Confere se a sessão continua sendo a mesma
      // que iniciou esta requisição.
      final tokenAtual = await LocalStorageService.getToken();

      // Impede que uma resposta antiga entregue dados
      // do usuário anterior.
      if (tokenAtual != token || _tokenDoCache != token) {
        return null;
      }

      value = usuario;
      return usuario;
    } finally {
      // Uma requisição antiga não pode limpar o controle
      // de uma requisição de outra sessão.
      if (_tokenDoCache == token) {
        _emAndamento = null;
      }

      servico.dispose();
    }
  }

  /// Limpa os dados armazenados da sessão.
  void _limpar() {
    _tokenDoCache = null;
    _emAndamento = null;
    value = null;
  }

  /// Deve ser chamado após invalidar o token no logout
  /// e durante a troca de usuário.
  void limparSessao() {
    _limpar();
  }

  /// Reinicia o estado para os testes automatizados.
  @visibleForTesting
  void reiniciar() {
    _limpar();
    criarServico = AdminDemandService.new;
  }
}
