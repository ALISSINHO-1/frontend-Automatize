import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_projeto_semestre/core/storage/local_storage_service.dart';
import 'package:frontend_projeto_semestre/features/demands/data/models/pedido_model.dart';
import 'package:frontend_projeto_semestre/features/demands/data/services/demand_service.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/demanda_store.dart';

/// Serviço simulado para controlar a ordem das respostas.
///
/// Não realiza requisições à API real.
class _DemandServiceControlado extends DemandService {
  _DemandServiceControlado()
    : super(client: MockClient((_) async => http.Response('[]', 200)));

  final chegouA = Completer<void>();
  final chegouB = Completer<void>();

  final respostaA = Completer<List<PedidoModel>>();
  final respostaB = Completer<List<PedidoModel>>();

  int chamadasA = 0;
  int chamadasB = 0;

  @override
  Future<List<PedidoModel>> buscarDemandas() async {
    final token = await LocalStorageService.getToken();

    if (token == 'token-cliente-A') {
      chamadasA++;

      if (!chegouA.isCompleted) {
        chegouA.complete();
      }

      return respostaA.future;
    }

    if (token == 'token-cliente-B') {
      chamadasB++;

      if (!chegouB.isCompleted) {
        chegouB.complete();
      }

      return respostaB.future;
    }

    throw StateError('Token inesperado: $token');
  }
}

void main() {
  setUp(LocalStorageService.removeToken);
  tearDown(LocalStorageService.removeToken);

  PedidoModel criarDemanda({
    required String id,
    required String clienteId,
    required String titulo,
  }) {
    return PedidoModel.fromJson({
      'id': id,
      'codigo_identificador': 'AUT-TESTE',
      'titulo': titulo,
      'descricao': 'Demanda utilizada no teste de sessão',
      'status': 'PLANEJAMENTO',
      'percentual_progresso': '15.00',
      'cliente_id': clienteId,
    });
  }

  for (final aRespondeAntesDeB in [true, false]) {
    test(
      aRespondeAntesDeB
          ? 'Cliente A não aparece enquanto B carrega demandas'
          : 'Resposta atrasada de A não substitui demandas de B',
      () async {
        final servico = _DemandServiceControlado();

        final store = DemandaStore.forTesting(servico);

        addTearDown(() {
          store.dispose();
          servico.dispose();
        });

        final demandaA = criarDemanda(
          id: '550e8400-e29b-41d4-a716-44665544000a',
          clienteId: 'cliente-A',
          titulo: 'Demanda exclusiva do cliente A',
        );

        final demandaB = criarDemanda(
          id: '550e8400-e29b-41d4-a716-44665544000b',
          clienteId: 'cliente-B',
          titulo: 'Demanda exclusiva do cliente B',
        );

        // ETAPA 1: cliente A faz login.
        await LocalStorageService.saveToken('token-cliente-A');

        // A consulta começa, mas sua resposta fica pendente.
        final carregamentoA = store.carregarDemandas();

        await servico.chegouA.future;

        expect(store.carregando, isTrue);

        // ETAPA 2: cliente A encerra a sessão.
        await LocalStorageService.removeToken();

        store.limpar();

        expect(store.demandas, isEmpty);
        expect(store.carregado, isFalse);

        // ETAPA 3: cliente B faz login.
        await LocalStorageService.saveToken('token-cliente-B');

        final carregamentoB = store.carregarDemandas();

        await servico.chegouB.future;

        expect(store.demandas, isEmpty);
        expect(store.carregando, isTrue);

        if (aRespondeAntesDeB) {
          // CENÁRIO 1:
          // A responde enquanto B ainda está carregando.
          servico.respostaA.complete([demandaA]);

          await carregamentoA;

          // A resposta antiga não pode aparecer.
          expect(store.demandas, isEmpty);

          // O carregamento de B deve continuar.
          expect(store.carregando, isTrue);

          // Agora B recebe suas demandas.
          servico.respostaB.complete([demandaB]);

          await carregamentoB;
        } else {
          // CENÁRIO 2:
          // B recebe suas demandas primeiro.
          servico.respostaB.complete([demandaB]);

          await carregamentoB;

          expect(store.demandas, hasLength(1));

          expect(
            store.demandas.single.titulo,
            'Demanda exclusiva do cliente B',
          );

          // A resposta antiga chega depois.
          servico.respostaA.complete([demandaA]);

          await carregamentoA;
        }

        // VALIDAÇÃO FINAL:
        // Somente os dados do cliente B permanecem.
        expect(store.demandas, hasLength(1));

        expect(store.demandas.single.titulo, 'Demanda exclusiva do cliente B');

        expect(store.demandas.single.id, demandaB.id);

        expect(
          store.demandas.any((demanda) => demanda.titulo.contains('cliente A')),
          isFalse,
        );

        expect(store.carregado, isTrue);
        expect(store.carregando, isFalse);
        expect(store.erro, isNull);

        // Cada sessão iniciou somente sua própria consulta.
        expect(servico.chamadasA, 1);
        expect(servico.chamadasB, 1);

        // Cliente B continua autenticado.
        expect(await LocalStorageService.getToken(), 'token-cliente-B');
      },
    );
  }
}
