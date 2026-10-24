
import 'package:flutter/foundation.dart';

class DemandaItem {
  final int id;
  final String codigo;
  final String titulo;
  final String descricao;
  final String estado;
  final int progresso;

  const DemandaItem({
    required this.id,
    required this.codigo,
    required this.titulo,
    required this.descricao,
    required this.estado,
    required this.progresso,
  });
}

class DemandaStore extends ChangeNotifier {
  DemandaStore._();

  static final DemandaStore instance = DemandaStore._();

  final List<DemandaItem> _demandas = [
    const DemandaItem(
      id: 1,
      codigo: 'AUT-001',
      titulo: 'Manutenção de notebook',
      descricao: 'Verificar desempenho, teclado e sistema.',
      estado: 'Planejamento',
      progresso: 15,
    ),
    const DemandaItem(
      id: 2,
      codigo: 'AUT-002',
      titulo: 'Configuração de rede',
      descricao: 'Verificar conexão e configuração da rede.',
      estado: 'Homologação',
      progresso: 85,
    ),
    const DemandaItem(
      id: 3,
      codigo: 'AUT-003',
      titulo: 'Instalação de sistema',
      descricao: 'Realizar instalação e validar funcionamento.',
      estado: 'Concluído',
      progresso: 100,
    ),
  ];

  List<DemandaItem> get demandas =>
      List.unmodifiable(_demandas);

  int _progressoPorEstado(String estado) {
    switch (estado) {
      case 'Planejamento':
        return 15;
      case 'Homologação':
        return 85;
      case 'Concluído':
        return 100;
      default:
        return 0;
    }
  }

  void adicionar({
    required String titulo,
    required String descricao,
    required String estado,
  }) {
    final proximoId = _demandas.fold<int>(
          0,
          (maior, demanda) =>
              demanda.id > maior ? demanda.id : maior,
        ) +
        1;

    _demandas.insert(
      0,
      DemandaItem(
        id: proximoId,
        codigo: 'AUT-${proximoId.toString().padLeft(3, '0')}',
        titulo: titulo,
        descricao: descricao,
        estado: estado,
        progresso: _progressoPorEstado(estado),
      ),
    );

    notifyListeners();
  }

  void atualizar({
    required int id,
    required String titulo,
    required String descricao,
    required String estado,
  }) {
    final indice = _demandas.indexWhere(
      (demanda) => demanda.id == id,
    );

    if (indice == -1) return;

    final atual = _demandas[indice];

    _demandas[indice] = DemandaItem(
      id: atual.id,
      codigo: atual.codigo,
      titulo: titulo,
      descricao: descricao,
      estado: estado,
      progresso: _progressoPorEstado(estado),
    );

    notifyListeners();
  }

  void remover(int id) {
    final quantidadeAnterior = _demandas.length;

    _demandas.removeWhere(
      (demanda) => demanda.id == id,
    );

    if (_demandas.length != quantidadeAnterior) {
      notifyListeners();
    }
  }
}
