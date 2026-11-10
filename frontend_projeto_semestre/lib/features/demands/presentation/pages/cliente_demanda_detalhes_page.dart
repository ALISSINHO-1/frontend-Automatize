import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../data/models/pedido_model.dart';
import '../../data/services/cliente_demanda_detalhes_service.dart';

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

  static String _texto(Object? value, {String vazio = 'Não informado'}) {
    final texto = value?.toString().trim() ?? '';
    return texto.isEmpty ? vazio : texto;
  }

  static String _data(Object? value) {
    if (value == null) {
      return 'Não informada';
    }

    final data = DateTime.tryParse(value.toString());

    if (data == null) {
      return 'Não informada';
    }

    final local = data.toLocal();

    String doisDigitos(int n) => n.toString().padLeft(2, '0');

    return '${doisDigitos(local.day)}/'
        '${doisDigitos(local.month)}/${local.year} '
        '${doisDigitos(local.hour)}:'
        '${doisDigitos(local.minute)}';
  }

  static double? _progresso(Object? value) {
    if (value == null) {
      return null;
    }

    final numero = double.tryParse(value.toString());

    return numero?.clamp(0.0, 100.0).toDouble();
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
    final demanda = dados.demanda;

    final valorProgresso = _progresso(demanda['percentual_progresso']);

    final percentual = valorProgresso == null
        ? 'Não informado'
        : '${valorProgresso.toStringAsFixed(2).replaceAll('.', ',')}%';

    final etapas = [...dados.etapas]
      ..sort(
        (a, b) => ((a['ordem'] as num?)?.toInt() ?? 0).compareTo(
          (b['ordem'] as num?)?.toInt() ?? 0,
        ),
      );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 950),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Título da demanda.
            Text(
              _texto(demanda['titulo']),
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 8),

            Text(
              'Código: '
              '${_texto(demanda['codigo_identificador'])}',
            ),

            const SizedBox(height: 16),

            // SCRUM-112:
            // Informações recebidas da API.
            _bloco('Detalhes da demanda', [
              _linha(
                'Descrição',
                _texto(demanda['descricao'], vazio: 'Sem descrição'),
              ),
              _linha('Estado', _texto(demanda['status'])),
              _linha('Responsável (ID)', _texto(demanda['responsavel_id'])),
              _linha('Criada em', _data(demanda['created_at'])),
              _linha('Atualizada em', _data(demanda['updated_at'])),
              _linha('Iniciada em', _data(demanda['data_inicio'])),
              _linha('Previsão', _texto(demanda['data_previsao'])),
              _linha('Concluída em', _data(demanda['data_conclusao'])),
            ]),

            // SCRUM-113:
            // A avaliação aparece somente em homologação.
            if (_emHomologacao(demanda))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FilledButton.icon(
                  onPressed: () => _abrirHomologacao(demanda),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Avaliar entrega'),
                ),
              ),

            // SCRUM-114:
            // Botão de abertura e acompanhamento.
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
                onPressed: _abrirOcorrencias,
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Ocorrências da demanda'),
              ),
            ),

            // Progresso real informado pela API.
            _bloco('Progresso informado pela API', [
              Text(percentual),
              const SizedBox(height: 10),
              if (valorProgresso != null)
                LinearProgressIndicator(value: valorProgresso / 100),
            ]),

            // Etapas somente leitura.
            _bloco('Etapas do atendimento (somente leitura)', [
              if (etapas.isEmpty) const Text('Nenhuma etapa registrada.'),

              for (final etapa in etapas)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    etapa['concluida'] == true
                        ? Icons.check_circle_outline
                        : Icons.pending_outlined,
                  ),
                  title: Text(_texto(etapa['descricao'])),
                  subtitle: Text(
                    etapa['concluida'] == true
                        ? 'Concluída em '
                              '${_data(etapa['concluida_em'])}'
                        : 'Pendente',
                  ),
                ),
            ]),

            // Histórico da demanda.
            _bloco(
              'Histórico e registros de aceite '
              '(somente leitura)',
              [
                if (dados.historico.isEmpty)
                  const Text('Nenhum registro no histórico.'),

                for (final evento in dados.historico)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history),
                    title: Text(_texto(evento['acao'])),
                    subtitle: Text(
                      'Registrado em '
                      '${_data(evento['created_at'])}',
                    ),
                  ),

                const SizedBox(height: 8),

                const Text(
                  'O histórico é somente leitura. '
                  'A aprovação e a rejeição são '
                  'realizadas na tela de avaliação.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bloco(String titulo, List<Widget> conteudo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...conteudo,
          ],
        ),
      ),
    );
  }

  Widget _linha(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $valor'),
    );
  }
}
