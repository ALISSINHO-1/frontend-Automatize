import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../app/app.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../models/pedido_model.dart';

class DemandServiceException implements Exception {
  final String mensagem;
  final int? statusCode;

  const DemandServiceException(this.mensagem, {this.statusCode});

  @override
  String toString() => mensagem;
}

class DemandFilters {
  const DemandFilters({
    this.busca,
    this.status,
    this.clienteId,
    this.responsavelId,
    this.criadoDe,
    this.criadoAte,
  });

  final String? busca;
  final String? status;
  final String? clienteId;
  final String? responsavelId;
  final DateTime? criadoDe;
  final DateTime? criadoAte;

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};

    void adicionar(String chave, String? valor) {
      if (valor != null && valor.trim().isNotEmpty) {
        params[chave] = valor.trim();
      }
    }

    adicionar('busca', busca);
    adicionar('status', status);
    adicionar('cliente_id', clienteId);
    adicionar('responsavel_id', responsavelId);
    adicionar('criado_de', criadoDe?.toIso8601String());
    adicionar('criado_ate', criadoAte?.toIso8601String());

    return params;
  }
}

class DemandIndicators {
  const DemandIndicators({required this.total, required this.porStatus});

  final int total;
  final Map<String, int> porStatus;

  factory DemandIndicators.fromJson(Map<String, dynamic> json) {
    final total = json['total'];
    final status = json['por_status'];

    if (total is! int || total < 0 || status is! Map<String, dynamic>) {
      throw const FormatException('A API retornou indicadores inválidos.');
    }

    final contagens = <String, int>{};

    for (final entry in status.entries) {
      if (entry.value is! int || (entry.value as int) < 0) {
        throw const FormatException('A API retornou uma contagem inválida.');
      }

      contagens[entry.key] = entry.value as int;
    }

    return DemandIndicators(total: total, porStatus: contagens);
  }
}

class DemandService {
  DemandService({http.Client? client})
    : _client = client ?? AuthInterceptorClient(navigatorKey: appNavigatorKey),
      _ownsClient = client == null;

  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  final bool _ownsClient;

  // Mantido para compatibilidade com as telas existentes.
  // Percorre todas as páginas disponibilizadas pela API.
  Future<List<PedidoModel>> buscarDemandas() async {
    const tamanhoPagina = 100;
    final demandas = <PedidoModel>[];

    while (true) {
      final pagina = await buscarPaginaDemandas(
        offset: demandas.length,
        limit: tamanhoPagina,
      );

      demandas.addAll(pagina);

      if (pagina.length < tamanhoPagina) {
        return demandas;
      }
    }
  }

  // Consulta somente a página solicitada, aplicando filtros no servidor.
  Future<List<PedidoModel>> buscarPaginaDemandas({
    int offset = 0,
    int limit = 10,
    DemandFilters filtros = const DemandFilters(),
  }) async {
    if (offset < 0 || limit < 1 || limit > 100) {
      throw ArgumentError(
        'Paginação inválida: offset deve ser >= 0 e limit entre 1 e 100.',
      );
    }

    final params = filtros.toQueryParameters()
      ..['offset'] = '$offset'
      ..['limit'] = '$limit';

    final resposta = await _executar(
      () => _client.get(
        AppConfig.apiUri(ApiPaths.demandas).replace(queryParameters: params),
        headers: {'Accept': 'application/json'},
      ),
    );

    _verificarStatus(resposta, esperado: 200, operacao: 'carregar demandas');

    final dynamic dados;

    try {
      dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    } on FormatException {
      throw const DemandServiceException('A API retornou um JSON inválido.');
    }

    if (dados is! List) {
      throw const DemandServiceException(
        'A API não retornou uma lista de demandas.',
      );
    }

    try {
      return dados.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Uma demanda está em formato inválido.');
        }

        return PedidoModel.fromJson(item);
      }).toList();
    } on FormatException catch (erro) {
      throw DemandServiceException(
        'Dados inválidos recebidos da API: ${erro.message}',
      );
    }
  }

  // Contadores calculados pelo backend para todo o conjunto filtrado.
  Future<DemandIndicators> buscarIndicadores({
    DemandFilters filtros = const DemandFilters(),
  }) async {
    final resposta = await _executar(
      () => _client.get(
        AppConfig.apiUri(
          '${ApiPaths.demandas}/indicadores',
        ).replace(queryParameters: filtros.toQueryParameters()),
        headers: {'Accept': 'application/json'},
      ),
    );

    _verificarStatus(resposta, esperado: 200, operacao: 'carregar indicadores');

    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is! Map<String, dynamic>) {
        throw const FormatException('Formato de indicadores inválido.');
      }

      return DemandIndicators.fromJson(dados);
    } on FormatException catch (erro) {
      throw DemandServiceException(
        'Indicadores inválidos recebidos da API: ${erro.message}',
      );
    }
  }

  // Preservado para não quebrar o cadastro das telas existentes.
  Future<void> criarDemanda(String titulo, String descricao) async {
    final resposta = await _executar(
      () => _client.post(
        AppConfig.apiUri(ApiPaths.demandas),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'titulo': titulo, 'descricao': descricao}),
      ),
    );

    _verificarStatus(resposta, esperado: 201, operacao: 'criar demanda');
  }

  Future<http.Response> _executar(
    Future<http.Response> Function() requisicao,
  ) async {
    try {
      return await requisicao().timeout(_timeout);
    } on TimeoutException {
      throw const DemandServiceException(
        'O servidor demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const DemandServiceException(
        'Não foi possível conectar à API. Verifique sua conexão.',
      );
    }
  }

  void _verificarStatus(
    http.Response resposta, {
    required int esperado,
    required String operacao,
  }) {
    if (resposta.statusCode == esperado) return;

    final detalhe = _detalheFastApi(resposta);

    final mensagem = switch (resposta.statusCode) {
      401 => 'Sua sessão expirou. Faça login novamente.',
      403 => 'Você não tem permissão para realizar esta operação.',
      404 => 'O recurso solicitado não foi encontrado.',
      409 => 'A operação não pode ser realizada no estado atual.',
      422 =>
        detalhe == null
            ? 'Os dados enviados não foram aceitos pela API.'
            : 'Dados inválidos: $detalhe',
      _ =>
        'Não foi possível $operacao '
            '(HTTP ${resposta.statusCode}).',
    };

    throw DemandServiceException(mensagem, statusCode: resposta.statusCode);
  }

  static String? _detalheFastApi(http.Response resposta) {
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
            .map((erro) => erro['msg'])
            .whereType<String>()
            .toList();

        if (mensagens.isNotEmpty) {
          return mensagens.join('; ');
        }
      }
    } on FormatException {
      // Alguns erros HTTP não retornam JSON.
    }

    return null;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
