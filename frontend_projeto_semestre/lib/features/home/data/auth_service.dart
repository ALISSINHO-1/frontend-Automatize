import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

enum UserRole { admin, tecnico, cliente }

extension UserRoleApi on UserRole {
  String get apiValue => switch (this) {
    UserRole.admin => 'ADMIN',
    UserRole.tecnico => 'TECNICO',
    UserRole.cliente => 'CLIENTE',
  };
}

class AuthenticatedUser {
  const AuthenticatedUser({required this.id, required this.role});

  final String id;
  final UserRole role;

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final profile = json['perfil'];
    if (id is! String || id.isEmpty || profile is! String) {
      throw const FormatException(
        'A API não retornou id e perfil válidos para o usuário autenticado.',
      );
    }

    final role = switch (profile.trim().toUpperCase()) {
      'ADMIN' => UserRole.admin,
      'TECNICO' => UserRole.tecnico,
      'CLIENTE' => UserRole.cliente,
      _ => throw const FormatException(
        'A API retornou um perfil desconhecido.',
      ),
    };
    return AuthenticatedUser(id: id, role: role);
  }
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final AuthenticatedUser user;
}

abstract interface class CurrentUserProvider {
  Future<AuthenticatedUser> fetchCurrentUser(String accessToken);
}

/// The current backend has no authenticated current-user route.
///
/// Keep login closed until a trusted identity can be resolved. Tests may inject
/// a mock provider; production code must use a backend contract that exists.
class MissingCurrentUserProvider implements CurrentUserProvider {
  const MissingCurrentUserProvider();

  @override
  Future<AuthenticatedUser> fetchCurrentUser(String accessToken) {
    throw const ProfileContractUnavailableException();
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ProfileContractUnavailableException extends AuthException {
  const ProfileContractUnavailableException()
    : super(
        'A API autenticou as credenciais, mas não informa o perfil do usuário. '
        'O acesso aos painéis depende de um endpoint autenticado de identidade.',
      );
}

class AuthService {
  AuthService({
    http.Client? client,
    this.userProvider = const MissingCurrentUserProvider(),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final CurrentUserProvider userProvider;
  AuthSession? session;

  Future<AuthSession> login(String email, String senha) async {
    logout();
    late final http.Response response;
    try {
      response = await _client
          .post(
            AppConfig.apiUri('/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'senha': senha}),
          )
          .timeout(const Duration(seconds: 15));
    } on http.ClientException {
      throw const AuthException('Não foi possível conectar à API.');
    } on TimeoutException {
      throw const AuthException(
        'A API demorou para responder. Tente novamente.',
      );
    }

    if (response.statusCode == 401) {
      throw const AuthException(
        'E-mail ou senha incorretos, ou conta inativa.',
      );
    }
    if (response.statusCode == 403) {
      throw const AuthException('A API negou o acesso a esta conta.');
    }
    if (response.statusCode == 422) {
      throw const AuthException(
        'Confira os dados informados e tente novamente.',
      );
    }
    if (response.statusCode != 200) {
      throw AuthException('Falha no login: HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['access_token'] is! String ||
        (decoded['access_token'] as String).isEmpty) {
      throw const FormatException('Resposta da API sem token válido.');
    }

    final token = decoded['access_token'] as String;
    try {
      final user = await userProvider.fetchCurrentUser(token);
      session = AuthSession(accessToken: token, user: user);
      return session!;
    } on ProfileContractUnavailableException {
      logout();
      rethrow;
    } on http.ClientException {
      logout();
      throw const AuthException('Não foi possível consultar o perfil na API.');
    } on TimeoutException {
      logout();
      throw const AuthException('A consulta do perfil demorou para responder.');
    } catch (_) {
      logout();
      rethrow;
    }
  }

  void logout() => session = null;

  void dispose() => _client.close();
}
