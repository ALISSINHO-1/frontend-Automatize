import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../app/app.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/auth_interceptor.dart';

class TechnicalStageException implements Exception {
  const TechnicalStageException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class TechnicalStage {
  const TechnicalStage({
    required this.id,
    required this.pedidoId,
    required this.descricao,
    required this.ordem,
    required this.concluida,
    required this.concluidaEm,
    required this.concluidaPorId,
    required this.criadoPorId,
    required this.createdAt,
  });

  final String id;
  final String pedidoId;
  final String descricao;
  final int ordem;
  final bool concluida;
  final DateTime? concluidaEm;
  final String? concluidaPorId;
  final String criadoPorId;
  final DateTime createdAt;

  factory TechnicalStage.fromJson(Map<String, dynamic> json) {
    String texto(String campo) {
      final valor = json[campo];

      if (valor is! String || valor.trim().isEmpty) {
        throw FormatException('Campo inválido: $campo.');
      }

      return valor;
    }

    String? textoOpcional(String campo) {
      final valor = json[campo];

      if (valor == null) return null;

      if (valor is! String) {
        throw FormatException('Campo inválido: $campo.');
      }

      return valor;
    }

    DateTime data(String campo) {
      final valor = json[campo];

      if (valor is! String) {
        throw FormatException('Data inválida: $campo.');
      }

      final resultado = DateTime.tryParse(valor);

      if (resultado == null) {
        throw FormatException('Data inválida: $campo.');
      }

      return resultado;
    }

    DateTime? dataOpcional(String campo) {
      final valor = json[campo];

      if (valor == null) return null;

      if (valor is! String) {
        throw FormatException('Data inválida: $campo.');
      }

      final resultado = DateTime.tryParse(valor);

      if (resultado == null) {
        throw FormatException('Data inválida: $campo.');
      }

      return resultado;
    }

    final ordem = json['ordem'];
    final concluida = json['concluida'];

    if (ordem is! int || ordem < 1 || concluida is! bool) {
      throw const FormatException('Dados de etapa inválidos.');
    }

    return TechnicalStage(
      id: texto('id'),
      pedidoId: texto('pedido_id'),
      descricao: texto('descricao'),
      ordem: ordem,
      concluida: concluida,
      concluidaEm: dataOpcional('concluida_em'),
      concluidaPorId: textoOpcional('concluida_por_id'),
      criadoPorId: texto('criado_por_id'),
      createdAt: data('created_at'),
    );
  }
}

class TechnicalStageService {
  TechnicalStageService({http.Client? client})
    : _client = client ?? AuthInterceptorClient(navigatorKey: appNavigatorKey),
      _ownsClient = client == null;

  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;
  final bool _ownsClient;

  String _basePath(String demandaId) {
    return '/demandas/${Uri.encodeComponent(demandaId)}/etapas';
  }

  String _stagePath(String demandaId, String etapaId) {
    return '${_basePath(demandaId)}/${Uri.encodeComponent(etapaId)}';
  }

  Map<String, String> get _headers => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<List<TechnicalStage>> listarEtapas(String demandaId) async {
    final resposta = await _executar(
      () => _client.get(
        AppConfig.apiUri(_basePath(demandaId)),
        headers: _headers,
      ),
    );

    _verificarStatus(resposta, 200, 'listar etapas');

    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is! List) {
        throw const FormatException('Lista de etapas inválida.');
      }

      final etapas = dados.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Etapa inválida.');
        }

        return TechnicalStage.fromJson(item);
      }).toList();

      etapas.sort((a, b) => a.ordem.compareTo(b.ordem));

      return etapas;
    } on FormatException catch (erro) {
      throw TechnicalStageException(
        'Resposta inválida da API: ${erro.message}',
      );
    }
  }

  Future<TechnicalStage> criarEtapa(
    String demandaId, {
    required String descricao,
    int? ordem,
  }) async {
    final texto = descricao.trim();

    if (texto.isEmpty || texto.length > 255) {
      throw const TechnicalStageException(
        'Informe uma descrição de até 255 caracteres.',
      );
    }

    if (ordem != null && ordem < 1) {
      throw const TechnicalStageException('A posição deve ser maior que zero.');
    }

    final corpo = <String, dynamic>{'descricao': texto, 'ordem': ?ordem};

    final resposta = await _executar(
      () => _client.post(
        AppConfig.apiUri(_basePath(demandaId)),
        headers: _headers,
        body: jsonEncode(corpo),
      ),
    );

    _verificarStatus(resposta, 201, 'criar etapa');

    return _lerEtapa(resposta);
  }

  Future<TechnicalStage> editarEtapa(
    String demandaId,
    String etapaId, {
    String? descricao,
    int? ordem,
  }) async {
    final corpo = <String, dynamic>{};

    if (descricao != null) {
      final texto = descricao.trim();

      if (texto.length < 3 || texto.length > 255) {
        throw const TechnicalStageException(
          'A descrição deve ter entre 3 e 255 caracteres.',
        );
      }

      corpo['descricao'] = texto;
    }

    if (ordem != null) {
      if (ordem < 1) {
        throw const TechnicalStageException(
          'A posição deve ser maior que zero.',
        );
      }

      corpo['ordem'] = ordem;
    }

    if (corpo.isEmpty) {
      throw const TechnicalStageException('Informe pelo menos uma alteração.');
    }

    final resposta = await _executar(
      () => _client.patch(
        AppConfig.apiUri(_stagePath(demandaId, etapaId)),
        headers: _headers,
        body: jsonEncode(corpo),
      ),
    );

    _verificarStatus(resposta, 200, 'editar etapa');

    return _lerEtapa(resposta);
  }

  Future<TechnicalStage> concluirEtapa(String demandaId, String etapaId) async {
    final resposta = await _executar(
      () => _client.post(
        AppConfig.apiUri('${_stagePath(demandaId, etapaId)}/conclusao'),
        headers: _headers,
      ),
    );

    _verificarStatus(resposta, 200, 'concluir etapa');

    return _lerEtapa(resposta);
  }

  Future<void> excluirEtapa(
    String demandaId,
    String etapaId, {
    required String motivo,
  }) async {
    final justificativa = motivo.trim();

    if (justificativa.length < 10 || justificativa.length > 500) {
      throw const TechnicalStageException(
        'A justificativa deve ter entre 10 e 500 caracteres.',
      );
    }

    final uri = AppConfig.apiUri(
      _stagePath(demandaId, etapaId),
    ).replace(queryParameters: {'motivo': justificativa});

    final resposta = await _executar(
      () => _client.delete(uri, headers: _headers),
    );

    _verificarStatus(resposta, 204, 'excluir etapa');
  }

  TechnicalStage _lerEtapa(http.Response resposta) {
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is! Map<String, dynamic>) {
        throw const FormatException('Objeto de etapa inválido.');
      }

      return TechnicalStage.fromJson(dados);
    } on FormatException catch (erro) {
      throw TechnicalStageException(
        'Resposta inválida da API: ${erro.message}',
      );
    }
  }

  Future<http.Response> _executar(
    Future<http.Response> Function() requisicao,
  ) async {
    try {
      return await requisicao().timeout(_timeout);
    } on TimeoutException {
      throw const TechnicalStageException(
        'O servidor demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const TechnicalStageException('Não foi possível conectar à API.');
    }
  }

  void _verificarStatus(http.Response resposta, int esperado, String operacao) {
    if (resposta.statusCode == esperado) return;

    final mensagem = switch (resposta.statusCode) {
      401 => 'Sua sessão expirou. Entre novamente.',
      403 => 'Você não tem permissão para $operacao.',
      404 => 'Demanda ou etapa não encontrada.',
      409 => 'A operação não é permitida no estado atual.',
      422 => 'A API rejeitou os dados enviados.',
      _ => 'Erro ao $operacao (HTTP ${resposta.statusCode}).',
    };

    throw TechnicalStageException(mensagem, statusCode: resposta.statusCode);
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
