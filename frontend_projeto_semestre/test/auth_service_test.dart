import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend_projeto_semestre/features/home/data/auth_service.dart';

void main() {
  tearDown(AuthService.logout);

  test('login stores JWT only after successful API response', () async {
    final service = AuthService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/auth/login');
        expect(jsonDecode(request.body), {
          'email': 'usuario@exemplo.com',
          'senha': 'senha-teste',
        });
        return http.Response(
          jsonEncode({'access_token': 'token-teste', 'token_type': 'bearer'}),
          200,
        );
      }),
    );
    addTearDown(service.dispose);

    await service.login(' usuario@exemplo.com ', 'senha-teste');
    expect(AuthService.accessToken, 'token-teste');
  });

  test('invalid credentials never grant access', () async {
    final service = AuthService(
      client: MockClient((_) async => http.Response('{}', 401)),
    );
    addTearDown(service.dispose);

    await expectLater(service.login('a@b.com', 'errada'), throwsException);
    expect(AuthService.accessToken, isNull);
  });

  test('missing JWT never grants access', () async {
    final service = AuthService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    addTearDown(service.dispose);

    await expectLater(service.login('a@b.com', 'senha'), throwsFormatException);
    expect(AuthService.accessToken, isNull);
  });

  test('logout clears the in-memory token', () async {
    final service = AuthService(
      client: MockClient((_) async =>
          http.Response(jsonEncode({'access_token': 'test'}), 200)),
    );
    addTearDown(service.dispose);

    await service.login('a@b.com', 'senha');
    AuthService.logout();
    expect(AuthService.accessToken, isNull);
  });
}
