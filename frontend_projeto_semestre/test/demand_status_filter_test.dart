import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/features/demands/data/models/pedido_model.dart';
import 'package:frontend_projeto_semestre/features/demands/presentation/widgets/demand_status_filter.dart';

void main() {
  test('reconhece PLANEAMENTO retornado pela API', () {
    expect(
      DemandStatusFilter.filtrar(
        ['PLANEAMENTO', 'EXECUCAO'],
        'PLANEJAMENTO',
        (status) => status,
      ),
      ['PLANEAMENTO'],
    );
  });
  test('Filtra demandas pelos quatro estados', () {
    final demandas = ['PLANEJAMENTO', 'EXECUCAO', 'HOMOLOGACAO', 'CONCLUIDO']
        .asMap()
        .entries
        .map((item) {
          return PedidoModel(
            id: '${item.key + 1}',
            titulo: 'Demanda ${item.key + 1}',
            descricao: '',
            status: item.value,
            percentualProgresso: 0,
            clienteId: 'cliente-teste',
          );
        })
        .toList();

    for (final estado in DemandStatusFilter.estados) {
      final resultado = DemandStatusFilter.filtrar(
        demandas,
        estado,
        (pedido) => pedido.status,
      );

      expect(resultado.length, 1);
      expect(resultado.first.status, estado);
    }
  });

  test('Sem filtro retorna todas as demandas', () {
    final demandas = ['PLANEJAMENTO', 'EXECUCAO'];

    final resultado = DemandStatusFilter.filtrar(
      demandas,
      null,
      (estado) => estado,
    );

    expect(resultado.length, 2);
  });
}
