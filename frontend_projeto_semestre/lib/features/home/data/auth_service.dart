import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static String? accessToken;

  Future<void> login(String email, String senha) async {
    final response = await _client.post(
      AppConfig.apiUri('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'senha': senha}),
    );

    if (response.statusCode == 401) {
      throw Exception('E-mail ou senha incorretos.');
    }
    if (response.statusCode != 200) {
      throw Exception('Falha no login: HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['access_token'] is! String ||
        (decoded['access_token'] as String).isEmpty) {
      throw const FormatException('Resposta da API sem token válido.');
    }
    accessToken = decoded['access_token'] as String;
  }

  static void logout() => accessToken = null;

  void dispose() => _client.close();
}
