import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../app/app.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/auth_interceptor.dart';

class TechnicalOccurrenceException implements Exception {
  const TechnicalOccurrenceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class TechnicalOccurrence {
  const TechnicalOccurrence({
    required this.id,
    required this.pedidoId,
    required this.autorId,
    required this.tipo,
    required this.descricao,
    required this.statusAnterior,
    required this.statusNovo,
    required this.createdAt,
    required this.resolvida,
    required this.resolvidaEm,
    required this.resolvidaPorId,
    required this.descricaoResolucao,
  });

  final String id;
  final String pedidoId;
  final String autorId;
  final String tipo;
  final String descricao;
  final String? statusAnterior;
  final String? statusNovo;
  final DateTime? createdAt;
  final bool resolvida;
  final DateTime? resolvidaEm;
  final String? resolvidaPorId;
  final String? descricaoResolucao;

  factory TechnicalOccurrence.fromJson(Map<String, dynamic> json) {
    String textoObrigatorio(String campo) {
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

    final resolvida = json['resolvida'];

    if (resolvida is! bool) {
      throw const FormatException('Estado de resolução inválido.');
    }

    return TechnicalOccurrence(
      id: textoObrigatorio('id'),
      pedidoId: textoObrigatorio('pedido_id'),
      autorId: textoObrigatorio('autor_id'),
      tipo: textoObrigatorio('tipo'),
      descricao: textoObrigatorio('descricao'),
      statusAnterior: textoOpcional('status_anterior'),
      statusNovo: textoOpcional('status_novo'),
      createdAt: dataOpcional('created_at'),
      resolvida: resolvida,
      resolvidaEm: dataOpcional('resolvida_em'),
      resolvidaPorId: textoOpcional('resolvida_por_id'),
      descricaoResolucao: textoOpcional('descricao_resolucao'),
    );
  }
}

class TechnicalOccurrenceService {
  TechnicalOccurrenceService({http.Client? client})
    : _client = client ?? AuthInterceptorClient(navigatorKey: appNavigatorKey),
      _ownsClient = client == null;

  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;
  final bool _ownsClient;

  Map<String, String> get _headers => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  String _basePath(String demandaId) {
    return '/demandas/${Uri.encodeComponent(demandaId)}/ocorrencias';
  }

  String _resolucaoPath(String demandaId, String ocorrenciaId) {
    return '${_basePath(demandaId)}/'
        '${Uri.encodeComponent(ocorrenciaId)}/resolucao';
  }

  Future<List<TechnicalOccurrence>> listarOcorrencias(String demandaId) async {
    final resposta = await _executar(
      () => _client.get(
        AppConfig.apiUri(_basePath(demandaId)),
        headers: _headers,
      ),
    );

    _verificarStatus(resposta, esperado: 200, operacao: 'listar ocorrências');

    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is! List) {
        throw const FormatException('Lista de ocorrências inválida.');
      }

      final ocorrencias = dados.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Ocorrência inválida.');
        }

        return TechnicalOccurrence.fromJson(item);
      }).toList();

      ocorrencias.sort((a, b) {
        final dataA = a.createdAt;
        final dataB = b.createdAt;

        if (dataA == null && dataB == null) return 0;
        if (dataA == null) return 1;
        if (dataB == null) return -1;

        return dataB.compareTo(dataA);
      });

      return ocorrencias;
    } on FormatException catch (erro) {
      throw TechnicalOccurrenceException(
        'Resposta inválida da API: ${erro.message}',
      );
    }
  }

  Future<TechnicalOccurrence> criarOcorrencia(
    String demandaId, {
    required String tipo,
    required String descricao,
  }) async {
    final tipoNormalizado = tipo.trim().toUpperCase();
    final texto = descricao.trim();

    if (tipoNormalizado != 'ERRO' &&
        tipoNormalizado != 'SOLICITACAO_CORRECAO') {
      throw const TechnicalOccurrenceException(
        'Selecione um tipo de ocorrência válido.',
      );
    }

    if (texto.length < 10 || texto.length > 2000) {
      throw const TechnicalOccurrenceException(
        'A descrição deve ter entre 10 e 2000 caracteres.',
      );
    }

    final resposta = await _executar(
      () => _client.post(
        AppConfig.apiUri(_basePath(demandaId)),
        headers: _headers,
        body: jsonEncode({'tipo': tipoNormalizado, 'descricao': texto}),
      ),
    );

    _verificarStatus(resposta, esperado: 201, operacao: 'registrar ocorrência');

    return _lerOcorrencia(resposta);
  }

  Future<TechnicalOccurrence> resolverOcorrencia(
    String demandaId,
    String ocorrenciaId, {
    required String descricaoResolucao,
  }) async {
    final texto = descricaoResolucao.trim();

    if (texto.length < 10 || texto.length > 2000) {
      throw const TechnicalOccurrenceException(
        'A descrição da correção deve ter '
        'entre 10 e 2000 caracteres.',
      );
    }

    final resposta = await _executar(
      () => _client.post(
        AppConfig.apiUri(_resolucaoPath(demandaId, ocorrenciaId)),
        headers: _headers,
        body: jsonEncode({'descricao_resolucao': texto}),
      ),
    );

    _verificarStatus(resposta, esperado: 200, operacao: 'resolver ocorrência');

    return _lerOcorrencia(resposta);
  }

  TechnicalOccurrence _lerOcorrencia(http.Response resposta) {
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is! Map<String, dynamic>) {
        throw const FormatException('Objeto de ocorrência inválido.');
      }

      return TechnicalOccurrence.fromJson(dados);
    } on FormatException catch (erro) {
      throw TechnicalOccurrenceException(
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
      throw const TechnicalOccurrenceException(
        'O servidor demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const TechnicalOccurrenceException(
        'Não foi possível conectar à API.',
      );
    }
  }

  void _verificarStatus(
    http.Response resposta, {
    required int esperado,
    required String operacao,
  }) {
    if (resposta.statusCode == esperado) return;

    final detalhe = _lerDetalhe(resposta);

    final mensagem = switch (resposta.statusCode) {
      401 => 'Sua sessão expirou. Entre novamente.',
      403 => 'Você não tem permissão para $operacao.',
      404 =>
        'Demanda ou ocorrência não encontrada '
            'ou fora do seu acesso.',
      409 => detalhe ?? 'A operação não é permitida no estado atual.',
      422 => detalhe ?? 'A API rejeitou os dados enviados.',
      _ => 'Erro ao $operacao (HTTP ${resposta.statusCode}).',
    };

    throw TechnicalOccurrenceException(
      mensagem,
      statusCode: resposta.statusCode,
    );
  }

  String? _lerDetalhe(http.Response resposta) {
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is! Map<String, dynamic>) return null;

      final detalhe = dados['detail'];

      if (detalhe is String && detalhe.trim().isNotEmpty) {
        return detalhe;
      }

      if (detalhe is List) {
        final mensagens = detalhe
            .whereType<Map>()
            .map((item) => item['msg'])
            .whereType<String>()
            .toList();

        if (mensagens.isNotEmpty) {
          return mensagens.join('; ');
        }
      }
    } on FormatException {
      // Algumas respostas HTTP não possuem JSON.
    }

    return null;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
