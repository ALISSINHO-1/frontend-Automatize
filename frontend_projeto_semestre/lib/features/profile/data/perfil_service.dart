import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../app/app.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../admin/data/models/usuario_atual_model.dart';

class PerfilDetalhes {
  const PerfilDetalhes({
    required this.ativo,
    required this.emailVerificado,
    this.criadoEm,
    this.origemCadastro,
  });

  final bool ativo;
  final bool emailVerificado;
  final DateTime? criadoEm;
  final String? origemCadastro;

  factory PerfilDetalhes.fromJson(Map<String, dynamic> json) => PerfilDetalhes(
    ativo: json['ativo'] == true,
    emailVerificado: json['email_verificado'] == true,
    criadoEm: DateTime.tryParse(json['criado_em']?.toString() ?? ''),
    origemCadastro: json['origem_cadastro']?.toString(),
  );
}

class PerfilException implements Exception {
  const PerfilException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Somente a identidade presente no Bearer pode consultar e editar a conta.
class PerfilService {
  PerfilService({http.Client? client})
      : _client = client ?? AuthInterceptorClient(navigatorKey: appNavigatorKey),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<Object?> _request(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = AppConfig.apiUri(path);
    final headers = {'Accept': 'application/json', 'Content-Type': 'application/json'};
    late http.Response response;
    try {
      if (method == 'GET') {
        response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      } else if (method == 'PATCH') {
        response = await _client.patch(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
      } else {
        response = await _client.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
      }
    } on TimeoutException {
      throw const PerfilException('A conexão demorou. Tente novamente.');
    } on http.ClientException {
      throw const PerfilException('Não foi possível conectar à API.');
    }
    if (response.statusCode == 204) return null;
    Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw const PerfilException('Resposta inesperada do servidor.');
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Não foi possível concluir a operação.';
      if (json is Map<String, dynamic> && json['detail'] is String) {
        message = json['detail'] as String;
      } else if (response.statusCode >= 500) {
        message = 'O serviço está temporariamente indisponível.';
      }
      throw PerfilException(message);
    }
    return json;
  }

  Future<PerfilDetalhes> detalhes() async {
    final data = await _request('GET', '/auth/me/detalhes');
    if (data is! Map<String, dynamic>) throw const PerfilException('Dados de perfil inválidos.');
    return PerfilDetalhes.fromJson(data);
  }

  Future<UsuarioAtualModel> alterarNome(String nome) async {
    final data = await _request('PATCH', '/auth/me', body: {'nome': nome});
    if (data is! Map<String, dynamic>) throw const PerfilException('Dados de perfil inválidos.');
    return UsuarioAtualModel.fromJson(data);
  }

  Future<void> alterarSenha(String antiga, String nova) async {
    await _request('POST', '/auth/me/senha', body: {'senha_atual': antiga, 'nova_senha': nova});
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
