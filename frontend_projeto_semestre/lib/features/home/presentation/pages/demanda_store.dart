import 'package:flutter/foundation.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../demands/data/models/pedido_model.dart';
import '../../../demands/data/services/demand_service.dart';

// Modelo utilizado pelas telas do cliente.
class DemandaItem {
  final String id;
  final String codigo;
  final String titulo;
  final String descricao;
  final String estado;
  final double progresso;
  final bool progressoInformado;
  final DateTime? createdAt;

  const DemandaItem({
    required this.id,
    required this.codigo,
    required this.titulo,
    required this.descricao,
    required this.estado,
    required this.progresso,
    this.progressoInformado = true,
    this.createdAt,
  });

  // Converte os dados recebidos da API para a interface.
  factory DemandaItem.fromPedido(PedidoModel pedido) {
    return DemandaItem(
      id: pedido.id,
      codigo: pedido.codigoIdentificador ?? pedido.id,
      titulo: pedido.titulo,
      descricao: pedido.descricao,
      estado: pedido.status,
      progresso: pedido.percentualProgresso,
      progressoInformado: pedido.progressoInformado,
      createdAt: pedido.createdAt,
    );
  }
}

// Gerencia o carregamento e o estado das demandas.
class DemandaStore extends ChangeNotifier {
  DemandaStore._();

  static final DemandaStore instance = DemandaStore._();

  final DemandService _service = DemandService();

  List<DemandaItem> _demandas = [];

  bool _carregando = false;
  bool _carregado = false;

  String? _erro;
  String? _tokenDaLista;

  // Impede que uma requisição antiga altere uma nova sessão.
  int _versao = 0;

  // Dados disponíveis para as telas.
  List<DemandaItem> get demandas => List.unmodifiable(_demandas);

  bool get carregando => _carregando;
  bool get carregado => _carregado;
  String? get erro => _erro;

  // Consulta as demandas reais na API.
  Future<void> carregarDemandas() async {
    if (_carregando) return;

    final versaoAtual = ++_versao;

    _carregando = true;
    _erro = null;

    notifyListeners();

    try {
      final token = await LocalStorageService.getToken();

      if (_versao != versaoAtual) return;

      // Não permite consultas sem autenticação.
      if (token == null || token.isEmpty) {
        _demandas = [];
        _carregado = false;
        _tokenDaLista = null;
        _erro = 'Faça login para consultar suas demandas.';
        return;
      }

      // Não reutiliza dados de uma sessão anterior.
      if (token != _tokenDaLista) {
        _demandas = [];
        _carregado = false;
        _tokenDaLista = token;

        notifyListeners();
      }

      // Obtém os registros persistidos no backend.
      final registros = await _service.buscarDemandas();

      final tokenAtual = await LocalStorageService.getToken();

      if (_versao != versaoAtual) return;

      // Descarta a resposta se a sessão mudou.
      if (tokenAtual != token) {
        limpar();
        return;
      }

      _demandas = registros.map(DemandaItem.fromPedido).toList();

      _carregado = true;
      _erro = null;
    } catch (erro) {
      if (_versao != versaoAtual) return;

      final tokenAtual = await LocalStorageService.getToken();

      if (_versao != versaoAtual) return;

      // Evita apresentar erros de uma sessão anterior.
      if (tokenAtual != _tokenDaLista) {
        limpar();
        return;
      }

      _demandas = [];
      _carregado = false;
      _erro = erro.toString();
    } finally {
      if (_versao == versaoAtual) {
        _carregando = false;
        notifyListeners();
      }
    }
  }

  // Cadastra uma demanda e atualiza a listagem após sucesso.
  Future<void> adicionar({
    required String titulo,
    required String descricao,
  }) async {
    final token = await LocalStorageService.getToken();

    if (token == null || token.isEmpty) {
      throw StateError(
        'É necessário estar autenticado para cadastrar demandas.',
      );
    }

    // Só continua se a API confirmar o cadastro.
    await _service.criarDemanda(titulo, descricao);

    // Não atualiza a listagem de outra sessão.
    final tokenAtual = await LocalStorageService.getToken();

    if (tokenAtual != token) return;

    await carregarDemandas();
  }

  // Remove os dados da sessão atual.
  void limpar() {
    // Invalida requisições iniciadas anteriormente.
    _versao++;

    _demandas = [];
    _tokenDaLista = null;

    _carregando = false;
    _carregado = false;

    _erro = null;

    notifyListeners();
  }
}
