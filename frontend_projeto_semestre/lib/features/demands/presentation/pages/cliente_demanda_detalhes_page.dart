import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../data/models/pedido_model.dart';
import '../../data/services/cliente_demanda_detalhes_service.dart';
import '../widgets/cliente_demanda_overview.dart';

class ClienteDemandaDetalhesPage extends StatefulWidget {
  const ClienteDemandaDetalhesPage({
    super.key,
    required this.demandaId,
    this.service,
  });

  final String demandaId;
  final ClienteDemandaDetalhesService? service;

  @override
  State<ClienteDemandaDetalhesPage> createState() =>
      _ClienteDemandaDetalhesPageState();
}

class _ClienteDemandaDetalhesPageState
    extends State<ClienteDemandaDetalhesPage> {
  late ClienteDemandaDetalhesService _service;
  late bool _ownsService;
  late Future<ClienteDemandaDetalhes> _dados;

  @override
  void initState() {
    super.initState();

    _ownsService = widget.service == null;
    _service = widget.service ?? ClienteDemandaDetalhesService();

    _dados = _service.carregar(widget.demandaId);
  }

  @override
  void didUpdateWidget(covariant ClienteDemandaDetalhesPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.service != oldWidget.service ||
        widget.demandaId != oldWidget.demandaId) {
      if (_ownsService) {
        _service.dispose();
      }

      _ownsService = widget.service == null;
      _service = widget.service ?? ClienteDemandaDetalhesService();

      _dados = _service.carregar(widget.demandaId);
    }
  }

  @override
  void dispose() {
    if (_ownsService) {
      _service.dispose();
    }

    super.dispose();
  }

  // Atualiza os dados da demanda diretamente pela API.
  void _recarregar() {
    if (!mounted) return;

    setState(() {
      _dados = _service.carregar(widget.demandaId);
    });
  }

  // Identifica demandas que podem apresentar
  // o botão de avaliação da entrega.
  bool _emHomologacao(Map<String, dynamic> demanda) {
    return demanda['status']?.toString().trim().toUpperCase() == 'HOMOLOGACAO';
  }

  // SCRUM-113:
  // Abre a homologação com um PedidoModel.
  Future<void> _abrirHomologacao(Map<String, dynamic> dadosDemanda) async {
    late final PedidoModel pedido;

    try {
      pedido = PedidoModel.fromJson(dadosDemanda);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível preparar os dados '
            'da demanda para avaliação.',
          ),
        ),
      );

      return;
    }

    if (!mounted) return;

    final resultado = await Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed<bool>(AppRoutes.clienteHomologacao, arguments: pedido);

    if (!mounted) return;

    if (resultado == true) {
      _recarregar();
    }
  }

  // SCRUM-114:
  // Abre as ocorrências da demanda selecionada.
  // Ao retornar, consulta novamente os dados da API.
  Future<void> _abrirOcorrencias() async {
    await Navigator.of(context).pushNamed<void>(
      AppRoutes.clienteOcorrencias,
      arguments: widget.demandaId,
    );

    if (!mounted) return;

    _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F131C),
      appBar: AppBar(
        title: const Text('Acompanhamento da demanda'),
        actions: [
          IconButton(
            tooltip: 'Atualizar detalhes',
            icon: const Icon(Icons.refresh),
            onPressed: _recarregar,
          ),
        ],
      ),
      body: FutureBuilder<ClienteDemandaDetalhes>(
        future: _dados,
        builder: (context, snapshot) {
          // Estado de carregamento.
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          // Tratamento de erros da API.
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 42),
                    const SizedBox(height: 12),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _recarregar,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final dados = snapshot.data;

          if (dados == null) {
            return const Center(child: Text('Nenhuma informação disponível.'));
          }

          return _conteudo(dados);
        },
      ),
    );
  }

  Widget _conteudo(ClienteDemandaDetalhes dados) {
    return ClienteDemandaOverview(
      dados: dados,
      demandaId: widget.demandaId,
      onOcorrencias: _abrirOcorrencias,
      onAvaliar: _emHomologacao(dados.demanda)
          ? () => _abrirHomologacao(dados.demanda)
          : null,
    );
  }
}
