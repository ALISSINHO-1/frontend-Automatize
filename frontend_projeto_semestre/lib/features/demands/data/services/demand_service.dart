
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../app/app.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../models/pedido_model.dart';

class DemandService {
  DemandService({http.Client? client})
      : _client = client ??
            AuthInterceptorClient(
              navigatorKey: appNavigatorKey,
            ),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  // GET /demandas - Lista demandas utilizando Bearer Token.
  Future<List<PedidoModel>> buscarDemandas() async {
    final resposta = await _client.get(
      AppConfig.apiUri(ApiPaths.demandas),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (resposta.statusCode == 401) {
      throw Exception(
        'Sessão expirada ou inválida. Faça login novamente.',
      );
    }

    if (resposta.statusCode != 200) {
      throw Exception(
        'Erro ao carregar demandas (HTTP ${resposta.statusCode}).',
      );
    }

    final dados = jsonDecode(
      utf8.decode(resposta.bodyBytes),
    );

    if (dados is! List) {
      throw const FormatException(
        'A API não retornou uma lista de demandas.',
      );
    }

    return dados.map<PedidoModel>((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Uma demanda veio em formato inválido.',
        );
      }

      return PedidoModel.fromJson(item);
    }).toList();
  }

  // POST /demandas - Cria demanda utilizando Bearer Token.
  Future<void> criarDemanda(
    String titulo,
    String descricao,
  ) async {
    final resposta = await _client.post(
      AppConfig.apiUri(ApiPaths.demandas),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'titulo': titulo,
        'descricao': descricao,
      }),
    );

    if (resposta.statusCode == 401) {
      throw Exception(
        'Sessão expirada ou inválida. Faça login novamente.',
      );
    }

    if (resposta.statusCode != 200 &&
        resposta.statusCode != 201) {
      throw Exception(
        'Falha ao criar demanda (HTTP ${resposta.statusCode}): '
        '${utf8.decode(resposta.bodyBytes)}',
      );
    }
  }

  // Libera os recursos do cliente HTTP quando não for mais utilizado.
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
