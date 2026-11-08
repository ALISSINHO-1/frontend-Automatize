import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

enum CurrentUserRole { admin, tecnico, cliente }

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.role,
    this.nome,
    this.email,
  });

  final String id;
  final CurrentUserRole role;
  final String? nome;
  final String? email;

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final perfil = json['perfil'];
    final nome = json['nome'];
    final email = json['email'];

    if (id is! String ||
        id.trim().isEmpty ||
        perfil is! String ||
        perfil.trim().isEmpty) {
      throw const FormatException('A API não retornou id e perfil válidos.');
    }

    final role = switch (perfil.trim().toUpperCase()) {
      'ADMIN' => CurrentUserRole.admin,
      'TECNICO' => CurrentUserRole.tecnico,
      'CLIENTE' => CurrentUserRole.cliente,
      _ => throw const FormatException(
        'A API retornou um perfil desconhecido.',
      ),
    };

    return CurrentUser(
      id: id,
      role: role,
      nome: nome is String && nome.trim().isNotEmpty ? nome : null,
      email: email is String && email.trim().isNotEmpty ? email : null,
    );
  }
}

class CurrentUserService {
  CurrentUserService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<CurrentUser> fetchCurrentUser(String token) async {
    if (token.trim().isEmpty) {
      throw const FormatException('Token de autenticação não informado.');
    }

    final response = await _client
        .get(
          AppConfig.apiUri('/auth/me'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      throw const CurrentUserException(
        'Sessão inválida ou expirada.',
        statusCode: 401,
      );
    }

    if (response.statusCode == 403) {
      throw const CurrentUserException(
        'Acesso não autorizado.',
        statusCode: 403,
      );
    }

    if (response.statusCode != 200) {
      throw CurrentUserException(
        'Falha ao consultar identidade: HTTP ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Resposta inválida de /auth/me.');
    }

    return CurrentUser.fromJson(decoded);
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

class CurrentUserException implements Exception {
  const CurrentUserException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
