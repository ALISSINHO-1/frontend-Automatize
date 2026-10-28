
import 'package:flutter/foundation.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../demands/data/models/pedido_model.dart';
import '../../../demands/data/services/demand_service.dart';

class DemandaItem {
  final String id;
  final String codigo;
  final String titulo;
  final String descricao;
  final String estado;
  final double progresso;
  final DateTime? createdAt;

  const DemandaItem({
    required this.id,
    required this.codigo,
    required this.titulo,
    required this.descricao,
    required this.estado,
    required this.progresso,
    this.createdAt,
  });

  // Converte o modelo da API para o modelo da interface.
  factory DemandaItem.fromPedido(PedidoModel pedido) {
    return DemandaItem(
      id: pedido.id,
      codigo: pedido.codigoIdentificador ?? pedido.id,
      titulo: pedido.titulo,
      descricao: pedido.descricao,
      estado: pedido.status,
      progresso: pedido.percentualProgresso,
      createdAt: pedido.createdAt,
    );
  }
}

class DemandaStore extends ChangeNotifier {
  DemandaStore._();

  static final DemandaStore instance = DemandaStore._();

  final DemandService _service = DemandService();

  List<DemandaItem> _demandas = [];
  bool _carregando = false;
  bool _carregado = false;
  String? _erro;
  String? _tokenDaLista;

  List<DemandaItem> get demandas =>
      List.unmodifiable(_demandas);

  bool get carregando => _carregando;
  bool get carregado => _carregado;
  String? get erro => _erro;

  // Carrega demandas reais por meio do serviço.
  Future<void> carregarDemandas() async {
    if (_carregando) return;

    _carregando = true;
    _erro = null;
    notifyListeners();

    final token = await LocalStorageService.getToken();

    if (token == null || token.isEmpty) {
      limpar();

      _erro = 'Faça login para consultar suas demandas.';
      notifyListeners();
      return;
    }

    // Não reaproveita dados de outra sessão.
    if (token != _tokenDaLista) {
      _demandas = [];
      _carregado = false;
      _tokenDaLista = token;
    }

    try {
      final registros = await _service.buscarDemandas();

      if (await LocalStorageService.getToken() != token) {
        limpar();
        return;
      }

      _demandas = registros
          .map(DemandaItem.fromPedido)
          .toList();

      _carregado = true;
    } catch (erro) {
      _demandas = [];
      _carregado = false;
      _erro = erro.toString();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // Só atualiza a listagem após o cadastro confirmado.
  Future<void> adicionar({
    required String titulo,
    required String descricao,
  }) async {
    await _service.criarDemanda(titulo, descricao);
    await carregarDemandas();
  }

  // Limpa as informações da sessão.
  void limpar() {
    _demandas = [];
    _tokenDaLista = null;
    _carregando = false;
    _carregado = false;
    _erro = null;

    notifyListeners();
  }
}
