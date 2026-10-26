import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend_projeto_semestre/features/home/data/auth_service.dart';

class _MockCurrentUserProvider implements CurrentUserProvider {
  _MockCurrentUserProvider(this.user);
  final AuthenticatedUser user;
  String? receivedToken;

  @override
  Future<AuthenticatedUser> fetchCurrentUser(String accessToken) async {
    receivedToken = accessToken;
    return user;
  }
}

void main() {
  test(
    'login keeps a session only after token and trusted identity resolve',
    () async {
      final provider = _MockCurrentUserProvider(
        const AuthenticatedUser(id: 'user-123', role: UserRole.admin),
      );
      final service = AuthService(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/auth/login');
          expect(jsonDecode(request.body), {
            'email': 'usuario@exemplo.test',
            'senha': 'senha-falsa-de-teste',
          });
          return http.Response(
            jsonEncode({'access_token': 'jwt-de-mock', 'token_type': 'bearer'}),
            200,
          );
        }),
        userProvider: provider,
      );
      addTearDown(service.dispose);

      final session = await service.login(
        ' usuario@exemplo.test ',
        'senha-falsa-de-teste',
      );

      expect(provider.receivedToken, 'jwt-de-mock');
      expect(session.accessToken, 'jwt-de-mock');
      expect(session.user.role, UserRole.admin);
      expect(service.session, same(session));
    },
  );

  test(
    'does not create a session when the backend has no identity contract',
    () async {
      final service = AuthService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'access_token': 'jwt-de-mock', 'token_type': 'bearer'}),
            200,
          ),
        ),
      );
      addTearDown(service.dispose);

      await expectLater(
        service.login('usuario@exemplo.test', 'senha-falsa-de-teste'),
        throwsA(isA<ProfileContractUnavailableException>()),
      );
      expect(service.session, isNull);
    },
  );

  test('invalid credentials never grant access', () async {
    final service = AuthService(
      client: MockClient((_) async => http.Response('{}', 401)),
      userProvider: _MockCurrentUserProvider(
        const AuthenticatedUser(id: 'user-123', role: UserRole.cliente),
      ),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.login('usuario@exemplo.test', 'senha-errada-de-teste'),
      throwsA(isA<AuthException>()),
    );
    expect(service.session, isNull);
  });

  test('handles forbidden, invalid payload, and connection errors', () async {
    for (final status in [403, 422]) {
      final service = AuthService(
        client: MockClient((_) async => http.Response('{}', status)),
      );
      addTearDown(service.dispose);
      await expectLater(
        service.login('usuario@exemplo.test', 'senha-falsa-de-teste'),
        throwsA(isA<AuthException>()),
      );
    }

    final malformed = AuthService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    addTearDown(malformed.dispose);
    await expectLater(
      malformed.login('usuario@exemplo.test', 'senha-falsa-de-teste'),
      throwsFormatException,
    );

    final offline = AuthService(
      client: MockClient(
        (_) async => throw http.ClientException('mock offline'),
      ),
    );
    addTearDown(offline.dispose);
    await expectLater(
      offline.login('usuario@exemplo.test', 'senha-falsa-de-teste'),
      throwsA(isA<AuthException>()),
    );
  });

  test('profile parser accepts only the official profile names', () {
    expect(
      AuthenticatedUser.fromJson({'id': 'user-123', 'perfil': 'TECNICO'}).role,
      UserRole.tecnico,
    );
    expect(
      () => AuthenticatedUser.fromJson({'id': 'user-123', 'perfil': 'ROOT'}),
      throwsFormatException,
    );
  });

  test('logout clears the session', () async {
    final service = AuthService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'access_token': 'jwt-de-mock', 'token_type': 'bearer'}),
          200,
        ),
      ),
      userProvider: _MockCurrentUserProvider(
        const AuthenticatedUser(id: 'user-123', role: UserRole.cliente),
      ),
    );
    addTearDown(service.dispose);

    await service.login('usuario@exemplo.test', 'senha-falsa-de-teste');
    service.logout();
    expect(service.session, isNull);
  });
}
