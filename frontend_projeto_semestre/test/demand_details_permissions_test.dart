import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend_projeto_semestre/features/demands/data/services/demand_service.dart';
import 'package:frontend_projeto_semestre/features/demands/presentation/pages/demand_details_page.dart';
import 'package:frontend_projeto_semestre/features/home/data/auth_service.dart';

Future<void> _openDetails(
  WidgetTester tester, {
  required UserRole role,
  required String status,
}) async {
  final service = DemandService(
    accessToken: 'jwt-mock',
    client: MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer jwt-mock');
      if (request.url.path.endsWith('/historico') ||
          request.url.path.endsWith('/etapas')) {
        return http.Response('[]', 200);
      }
      return http.Response(
        jsonEncode({
          'id': 'demand-1',
          'codigo_identificador': 'DEM-0001',
          'titulo': 'Demanda retornada pelo mock',
          'descricao': 'Detalhe mockado para teste de autorização visual.',
          'status': status,
          'percentual_progresso': '85.00',
          'cliente_id': 'client-1',
          'responsavel_id': 'tech-1',
          'created_at': '2026-10-20T10:00:00Z',
          'updated_at': '2026-10-25T10:00:00Z',
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );
  addTearDown(service.dispose);
  final session = AuthSession(
    accessToken: 'jwt-mock',
    user: AuthenticatedUser(id: 'user-1', role: role),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: DemandDetailsPage(
        key: ValueKey(status),
        demandId: 'demand-1',
        session: session,
        onLogout: () {},
        service: service,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('client can decide only on a HOMOLOGACAO demand', (tester) async {
    await _openDetails(tester, role: UserRole.cliente, status: 'HOMOLOGACAO');
    expect(find.text('Aprovar'), findsOneWidget);
    expect(find.text('Reprovar'), findsOneWidget);

    await _openDetails(tester, role: UserRole.cliente, status: 'EXECUCAO');
    expect(find.text('Aprovar'), findsNothing);
    expect(find.text('Reprovar'), findsNothing);
  });

  testWidgets('admin does not receive client approval controls', (
    tester,
  ) async {
    await _openDetails(tester, role: UserRole.admin, status: 'HOMOLOGACAO');
    expect(
      find.text('Aguardando decisão do cliente responsável.'),
      findsOneWidget,
    );
    expect(find.text('Aprovar'), findsNothing);
    expect(find.text('Reprovar'), findsNothing);
  });
}
