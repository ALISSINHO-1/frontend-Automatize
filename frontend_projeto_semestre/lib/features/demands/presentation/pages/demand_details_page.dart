import 'package:flutter/material.dart';

import '../../../home/data/auth_service.dart';
import '../../data/models/historico_estado_model.dart';
import '../../data/models/pedido_model.dart';
import '../../data/services/demand_service.dart';
import '../widgets/demand_history_timeline.dart';
import '../widgets/demand_homologation_card.dart';

class DemandDetailsPage extends StatefulWidget {
  const DemandDetailsPage({
    super.key,
    required this.demandId,
    required this.session,
    required this.onLogout,
    this.pedido,
    this.service,
  });

  final String demandId;
  final PedidoModel? pedido;
  final AuthSession session;
  final VoidCallback onLogout;
  final DemandService? service;

  @override
  State<DemandDetailsPage> createState() => _DemandDetailsPageState();
}

class _DemandDetailsPageState extends State<DemandDetailsPage> {
  late final DemandService _service;
  late final bool _ownsService;
  late Future<PedidoModel> _demand;
  late Future<List<HistoricoEstadoModel>> _history;
  late Future<List<EtapaOperacionalModel>> _stages;
  bool _sendingDecision = false;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service =
        widget.service ??
        DemandService(
          accessToken: widget.session.accessToken,
          onUnauthorized: widget.onLogout,
        );
    _reload();
  }

  @override
  void dispose() {
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  void _reload() {
    _demand = _service.buscarDemanda(widget.demandId);
    _history = _service.buscarHistorico(widget.demandId);
    _stages = _service.buscarEtapas(widget.demandId);
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Não informado';
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  Future<void> _approve() async {
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _ApprovalDialog(),
    );
    if (values == null || !mounted) return;
    await _sendDecision(
      () => _service.aprovarHomologacao(
        widget.demandId,
        versaoEntregavel: values['versao']!,
        declaracaoAceite: values['declaracao']!,
      ),
    );
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectionDialog(),
    );
    if (reason == null || !mounted) return;
    await _sendDecision(
      () => _service.rejeitarHomologacao(widget.demandId, motivo: reason),
    );
  }

  Future<void> _sendDecision(Future<void> Function() action) async {
    setState(() => _sendingDecision = true);
    try {
      await action();
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A decisão foi registrada pela API.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível registrar a decisão: $error')),
      );
    } finally {
      if (mounted) setState(() => _sendingDecision = false);
    }
  }

  Future<void> _runOperation(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _sendingDecision = true);
    try {
      await action();
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('A API não registrou a operação: $error')),
      );
    } finally {
      if (mounted) setState(() => _sendingDecision = false);
    }
  }

  Future<void> _addStage() async {
    final description = await showDialog<String>(
      context: context,
      builder: (context) => const _StageDialog(),
    );
    if (description == null || !mounted) return;
    await _runOperation(() async {
      await _service.adicionarEtapa(widget.demandId, descricao: description);
    }, successMessage: 'A etapa foi cadastrada pela API.');
  }

  Future<void> _completeStage(String stageId) => _runOperation(() async {
    await _service.concluirEtapa(widget.demandId, stageId);
  }, successMessage: 'A etapa foi concluída pela API.');

  Future<void> _changeStatus(String status) => _runOperation(() async {
    await _service.alterarStatus(widget.demandId, status);
  }, successMessage: 'O estado foi atualizado pela API.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da demanda'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<PedidoModel>(
        future: _demand,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível abrir esta demanda.\n${snapshot.error ?? ''}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final demand = snapshot.requireData;
          final canDecide =
              widget.session.user.role == UserRole.cliente &&
              demand.status.trim().toUpperCase() == 'HOMOLOGACAO';
          final status = demand.status.trim().toUpperCase();
          final canOperate =
              widget.session.user.role == UserRole.admin ||
              (widget.session.user.role == UserRole.tecnico &&
                  widget.session.user.id == demand.responsavelId);
          final progress = demand.percentualProgresso;
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demand.codigoIdentificador ?? 'DEMANDA',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        demand.titulo,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 32,
                                runSpacing: 18,
                                children: [
                                  _Info(label: 'ESTADO', value: demand.status),
                                  if (widget.session.user.role ==
                                      UserRole.admin)
                                    _Info(
                                      label: 'CLIENTE ID',
                                      value: demand.clienteId,
                                    ),
                                  _Info(
                                    label: 'RESPONSÁVEL',
                                    value:
                                        demand.responsavelId ?? 'Não atribuído',
                                  ),
                                  _Info(
                                    label: 'CRIADA EM',
                                    value: _formatDate(demand.createdAt),
                                  ),
                                  _Info(
                                    label: 'ATUALIZADA EM',
                                    value: _formatDate(demand.updatedAt),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Descrição',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                demand.descricao.isEmpty
                                    ? 'Sem descrição informada.'
                                    : demand.descricao,
                              ),
                              const SizedBox(height: 24),
                              if (progress == null)
                                const Text('Progresso não informado pela API.')
                              else ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progresso',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    Text('${progress.toStringAsFixed(0)}%'),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: (progress / 100).clamp(0.0, 1.0),
                                  minHeight: 9,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _Stages(future: _stages),
                      if (canOperate &&
                          (status == 'PLANEAMENTO' ||
                              status == 'EXECUCAO')) ...[
                        const SizedBox(height: 12),
                        _TechnicalActions(
                          future: _stages,
                          status: status,
                          busy: _sendingDecision,
                          onAddStage: _addStage,
                          onCompleteStage: _completeStage,
                          onStartExecution: () => _changeStatus('EXECUCAO'),
                          onSendToHomologation: () =>
                              _changeStatus('HOMOLOGACAO'),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FutureBuilder<List<HistoricoEstadoModel>>(
                        future: _history,
                        builder: (context, historySnapshot) =>
                            DemandHistoryTimeline(
                              historico: historySnapshot.data ?? const [],
                              carregando:
                                  historySnapshot.connectionState ==
                                  ConnectionState.waiting,
                              erro: historySnapshot.hasError
                                  ? historySnapshot.error.toString()
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 20),
                      DemandHomologationCard(
                        status: demand.status,
                        mostrarAcoes: canDecide,
                        onAprovar: _sendingDecision ? null : _approve,
                        onReprovar: _sendingDecision ? null : _reject,
                      ),
                      if (_sendingDecision) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 5),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}

class _Stages extends StatelessWidget {
  const _Stages({required this.future});
  final Future<List<EtapaOperacionalModel>> future;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Etapas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<List<EtapaOperacionalModel>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text(
                  'Não foi possível carregar as etapas: ${snapshot.error}',
                );
              }
              final stages = snapshot.data ?? const [];
              if (stages.isEmpty) {
                return const Text('Nenhuma etapa cadastrada.');
              }
              return Column(
                children: stages
                    .map(
                      (stage) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: stage.concluida,
                        onChanged: null,
                        title: Text(stage.descricao),
                        subtitle: Text(
                          stage.concluida ? 'Concluída' : 'Pendente',
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _TechnicalActions extends StatelessWidget {
  const _TechnicalActions({
    required this.future,
    required this.status,
    required this.busy,
    required this.onAddStage,
    required this.onCompleteStage,
    required this.onStartExecution,
    required this.onSendToHomologation,
  });

  final Future<List<EtapaOperacionalModel>> future;
  final String status;
  final bool busy;
  final VoidCallback onAddStage;
  final ValueChanged<String> onCompleteStage;
  final VoidCallback onStartExecution;
  final VoidCallback onSendToHomologation;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Atualizar andamento',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (status == 'PLANEAMENTO')
            FilledButton.icon(
              onPressed: busy ? null : onStartExecution,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar execução'),
            ),
          if (status == 'PLANEAMENTO' || status == 'EXECUCAO')
            OutlinedButton.icon(
              onPressed: busy ? null : onAddStage,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar etapa'),
            ),
          if (status == 'EXECUCAO')
            FutureBuilder<List<EtapaOperacionalModel>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Text('Etapas indisponíveis: ${snapshot.error}');
                }
                final stages = snapshot.data ?? const [];
                final canSend =
                    stages.isNotEmpty &&
                    stages.every((stage) => stage.concluida);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final stage in stages.where((item) => !item.concluida))
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: busy
                              ? null
                              : () => onCompleteStage(stage.id),
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text('Concluir: ${stage.descricao}'),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: busy || !canSend ? null : onSendToHomologation,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Enviar para homologação'),
                    ),
                    if (!canSend)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Cadastre e conclua todas as etapas antes de enviar.',
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    ),
  );
}

class _StageDialog extends StatefulWidget {
  const _StageDialog();
  @override
  State<_StageDialog> createState() => _StageDialogState();
}

class _StageDialogState extends State<_StageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Adicionar etapa operacional'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _description,
        maxLength: 255,
        decoration: const InputDecoration(labelText: 'Descrição'),
        validator: (value) => value == null || value.trim().length < 3
            ? 'Informe ao menos 3 caracteres.'
            : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(context, _description.text.trim());
        },
        child: const Text('Cadastrar etapa'),
      ),
    ],
  );
}

class _ApprovalDialog extends StatefulWidget {
  const _ApprovalDialog();
  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _version = TextEditingController();
  final _statement = TextEditingController();

  @override
  void dispose() {
    _version.dispose();
    _statement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Aprovar homologação'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _version,
            maxLength: 50,
            decoration: const InputDecoration(
              labelText: 'Versão do entregável',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Informe a versão.'
                : null,
          ),
          TextFormField(
            controller: _statement,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Declaração de aceite',
            ),
            validator: (value) => value == null || value.trim().length < 10
                ? 'Informe ao menos 10 caracteres.'
                : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(context, {
            'versao': _version.text.trim(),
            'declaracao': _statement.text.trim(),
          });
        },
        child: const Text('Confirmar aceite'),
      ),
    ],
  );
}

class _RejectionDialog extends StatefulWidget {
  const _RejectionDialog();
  @override
  State<_RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<_RejectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Solicitar ajustes'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _reason,
        minLines: 3,
        maxLines: 5,
        maxLength: 500,
        decoration: const InputDecoration(
          labelText: 'Motivo (mínimo 10 caracteres)',
        ),
        validator: (value) => value == null || value.trim().length < 10
            ? 'Explique os ajustes necessários.'
            : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(context, _reason.text.trim());
        },
        child: const Text('Enviar rejeição'),
      ),
    ],
  );
}
