import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend_projeto_semestre/features/profile/data/perfil_service.dart';

void main() {
  test('detalhes mostram dados reais, sem expor hashes ou chaves', () async {
    final service = PerfilService(client: MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/auth/me/detalhes');
      return http.Response(jsonEncode({
        'id': 'uuid-seguro', 'perfil': 'TECNICO',
        'nome': 'Técnico real', 'email': 'tecnico@example.com',
        'ativo': true, 'criado_em': '2026-01-01T10:00:00Z',
        'email_verificado': true, 'origem_cadastro': 'LEGADO',
      }), 200, headers: {'content-type': 'application/json; charset=utf-8'});
    }));
    final details = await service.detalhes();
    expect(details.ativo, isTrue);
    expect(details.emailVerificado, isTrue);
    expect(details.criadoEm?.year, 2026);
  });

  test('atualização do nome envia apenas o nome para o servidor', () async {
    final service = PerfilService(client: MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/auth/me');
      expect(jsonDecode(request.body), {'nome': 'Nome Alterado'});
      return http.Response(jsonEncode({
        'id': 'id-teste', 'nome': 'Nome Alterado',
        'email': 'cliente@example.com', 'perfil': 'CLIENTE'
      }), 200);
    }));
    final user = await service.alterarNome('Nome Alterado');
    expect(user.perfil, 'CLIENTE');
    expect(user.nome, 'Nome Alterado');
  });

  test('troca de senha usa senha atual e nova e exige sucesso HTTP', () async {
    final service = PerfilService(client: MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/auth/me/senha');
      expect(jsonDecode(request.body), {
        'senha_atual': 'antiga', 'nova_senha': 'nova-segura',
      });
      return http.Response('', 204);
    }));
    await service.alterarSenha('antiga', 'nova-segura');
  });

  test('erro do backend não é tratado como senha alterada', () async {
    final service = PerfilService(client: MockClient((request) async {
      return http.Response(jsonEncode({'detail': 'Senha atual incorreta.'}), 400);
    }));
    expect(service.alterarSenha('errada', 'nova-segura'),
        throwsA(isA<PerfilException>()));
  });
}
