import 'package:flutter/material.dart';

import '../../../../core/theme/redesign_colors.dart';

import '../../data/models/pedido_model.dart';

import '../../data/models/historico_estado_model.dart';

import '../../data/services/technical_stage_service.dart';

import '../widgets/demand_history_timeline.dart';

import 'technical_demand_attachments_page.dart';

import 'technical_demand_homologation_page.dart';

import '../../data/services/technical_homologation_service.dart';
import '../../data/services/technical_occurrence_service.dart';

class TechnicalDemandDetailsPage extends StatelessWidget {
  const TechnicalDemandDetailsPage({
    super.key,

    required this.demandId,

    this.pedido,
  });

  final String demandId;

  final PedidoModel? pedido;

  String get nomeResponsavel {
    final id = pedido?.responsavelId;

    return id == null || id.isEmpty ? 'Não atribuído' : 'ID: $id';
  }

  static String _formatarData(DateTime? data) {
    if (data == null) return 'Não informado';

    final local = data.toLocal();

    String dois(int valor) => valor.toString().padLeft(2, '0');

    return '${dois(local.day)}/${dois(local.month)}/${local.year}';
  }

  Color _corStatus(String status) {
    switch (status.trim().toUpperCase()) {
      case 'PLANEJAMENTO':
      case 'PLANEAMENTO':
        return RedesignColors.purple;

      case 'EXECUCAO':
        return RedesignColors.cyan;

      case 'HOMOLOGACAO':
        return RedesignColors.amber;

      case 'CONCLUIDO':
        return RedesignColors.green;

      default:
        return RedesignColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = pedido?.status ?? 'SEM DADOS';

    final corStatus = _corStatus(status);

    final progresso = (pedido?.percentualProgresso ?? 0)
        .clamp(0, 100)
        .toDouble();

    return Scaffold(
      backgroundColor: RedesignColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),

                    icon: const Icon(Icons.arrow_back_rounded, size: 18),

                    label: const Text('Minhas demandas'),

                    style: TextButton.styleFrom(
                      foregroundColor: RedesignColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'DEMANDA',

                    style: TextStyle(
                      color: RedesignColors.purple,

                      fontSize: 11,

                      fontWeight: FontWeight.bold,

                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 16,

                    runSpacing: 12,

                    crossAxisAlignment: WrapCrossAlignment.center,

                    children: [
                      Text(
                        pedido?.titulo ?? 'Detalhes indisponíveis',

                        style: const TextStyle(
                          color: RedesignColors.textPrimary,

                          fontSize: 28,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,

                          vertical: 8,
                        ),

                        decoration: BoxDecoration(
                          color: corStatus.withValues(alpha: 0.14),

                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: Text(
                          status.toUpperCase(),

                          style: TextStyle(
                            color: corStatus,

                            fontSize: 10,

                            fontWeight: FontWeight.bold,

                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Informações principais da demanda.
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(26),

                    decoration: BoxDecoration(
                      color: RedesignColors.card,

                      borderRadius: BorderRadius.circular(16),

                      border: Border.all(color: RedesignColors.border),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'Descrição',

                          style: TextStyle(
                            color: RedesignColors.textPrimary,

                            fontSize: 17,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          pedido?.descricao ?? 'Descrição não disponível.',

                          style: const TextStyle(
                            color: RedesignColors.textSecondary,

                            fontSize: 14,

                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 26),

                        const Divider(color: RedesignColors.border),

                        const SizedBox(height: 24),

                        Wrap(
                          spacing: 48,

                          runSpacing: 24,

                          children: [
                            _InformationItem(
                              label: 'RESPONSÁVEL',

                              value: nomeResponsavel,

                              icon: Icons.person_outline_rounded,

                              color: RedesignColors.purple,
                            ),

                            _InformationItem(
                              label: 'ESTADO',

                              value: status,

                              icon: Icons.sync_rounded,

                              color: corStatus,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            const Text(
                              'Progresso',

                              style: TextStyle(
                                color: RedesignColors.textPrimary,

                                fontSize: 15,

                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              '${progresso.toStringAsFixed(0)}%',

                              style: const TextStyle(
                                color: RedesignColors.textPrimary,

                                fontSize: 14,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),

                          child: LinearProgressIndicator(
                            value: progresso / 100,

                            minHeight: 9,

                            backgroundColor: RedesignColors.border,

                            valueColor: const AlwaysStoppedAnimation<Color>(
                              RedesignColors.purple,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        const Divider(color: RedesignColors.border),

                        const SizedBox(height: 24),

                        Wrap(
                          spacing: 48,

                          runSpacing: 24,

                          children: [
                            _InformationItem(
                              label: 'CRIADA EM',

                              value: _formatarData(pedido?.createdAt),

                              icon: Icons.calendar_today_outlined,

                              color: RedesignColors.cyan,
                            ),

                            _InformationItem(
                              label: 'ATUALIZADA EM',

                              value: _formatarData(pedido?.updatedAt),

                              icon: Icons.update_rounded,

                              color: RedesignColors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Acesso aos anexos existente.
                  FilledButton.icon(
                    onPressed: pedido == null
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TechnicalDemandAttachmentsPage(
                                  pedido: pedido!,
                                ),
                              ),
                            );
                          },

                    icon: const Icon(Icons.attach_file_rounded, size: 18),

                    label: const Text('Abrir anexos'),

                    style: FilledButton.styleFrom(
                      backgroundColor: RedesignColors.purple,

                      foregroundColor: Colors.white,

                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,

                        vertical: 15,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SCRUM-107: etapas operacionais reais da API.
                  _TechnicalWorkflowSections(
                    demandId: demandId,
                    statusDemanda: status,
                  ),

                  const SizedBox(height: 24),

                  // Histórico demonstrativo já existente.

                  // Ainda será integrado ao histórico real da API.
                  DemandHistoryTimeline(
                    historico: [
                      HistoricoEstadoModel(
                        estadoAnterior: null,

                        novoEstado: 'ABERTO',

                        usuarioResponsavel: 'Lucas Silva',

                        dataHora: DateTime(2026, 10, 15, 9, 30),
                      ),

                      HistoricoEstadoModel(
                        estadoAnterior: 'ABERTO',

                        novoEstado: 'EXECUCAO',

                        usuarioResponsavel: 'Lucas Silva',

                        dataHora: DateTime(2026, 10, 17, 14, 15),
                      ),

                      HistoricoEstadoModel(
                        estadoAnterior: 'EXECUCAO',

                        novoEstado: 'HOMOLOGACAO',

                        usuarioResponsavel: 'Lucas Silva',

                        dataHora: DateTime(2026, 10, 20, 10, 45),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Histórico demonstrativo. Os registros acima '
                    'ainda não representam o histórico real da API.',

                    style: TextStyle(
                      color: RedesignColors.textSecondary,

                      fontSize: 11,
                    ),
                  ),

                  // Homologação existente.
                  if (pedido?.status.toUpperCase() == 'HOMOLOGACAO') ...[
                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TechnicalDemandHomologationPage(
                              pedido: pedido!,
                            ),
                          ),
                        );
                      },

                      icon: const Icon(Icons.fact_check_outlined, size: 18),

                      label: const Text('Abrir homologação'),

                      style: FilledButton.styleFrom(
                        backgroundColor: RedesignColors.amber,

                        foregroundColor: RedesignColors.background,

                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,

                          vertical: 15,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: RedesignColors.purple.withValues(alpha: 0.06),

                      borderRadius: BorderRadius.circular(12),

                      border: Border.all(color: RedesignColors.border),
                    ),

                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,

                          color: RedesignColors.cyan,

                          size: 21,
                        ),

                        SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            'As etapas operacionais são consultadas '
                            'diretamente na API. O progresso exibido '
                            'acima corresponde aos dados da demanda '
                            'recebidos ao abrir esta tela.',

                            style: TextStyle(
                              color: RedesignColors.textSecondary,

                              fontSize: 12,

                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Mantém o estado de homologação sincronizado com etapas e ocorrências.
class _TechnicalWorkflowSections extends StatefulWidget {
  const _TechnicalWorkflowSections({
    required this.demandId,
    required this.statusDemanda,
  });

  final String demandId;
  final String statusDemanda;

  @override
  State<_TechnicalWorkflowSections> createState() =>
      _TechnicalWorkflowSectionsState();
}

class _TechnicalWorkflowSectionsState
    extends State<_TechnicalWorkflowSections> {
  int _revisao = 0;

  void _dadosAlterados() {
    if (!mounted) return;
    setState(() => _revisao++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TechnicalStagesSection(
          key: ValueKey(widget.demandId),
          demandId: widget.demandId,
          statusDemanda: widget.statusDemanda,
          onDadosAlterados: _dadosAlterados,
        ),
        const SizedBox(height: 24),
        _TechnicalOccurrencesSection(
          demandId: widget.demandId,
          onDadosAlterados: _dadosAlterados,
        ),
        const SizedBox(height: 24),
        _TechnicalHomologationAction(
          key: ValueKey('${widget.demandId}-$_revisao'),
          demandId: widget.demandId,
        ),
      ],
    );
  }
}

class _TechnicalStagesSection extends StatefulWidget {
  const _TechnicalStagesSection({
    super.key,

    required this.demandId,

    required this.statusDemanda,

    required this.onDadosAlterados,
  });

  final String demandId;

  final String statusDemanda;

  final VoidCallback onDadosAlterados;

  @override
  State<_TechnicalStagesSection> createState() =>
      _TechnicalStagesSectionState();
}

class _TechnicalStagesSectionState extends State<_TechnicalStagesSection> {
  final TechnicalStageService _service = TechnicalStageService();

  late Future<List<TechnicalStage>> _future;

  bool _executando = false;

  bool get _podeAlterar {
    final status = widget.statusDemanda.trim().toUpperCase();

    return status == 'EXECUCAO';
  }

  @override
  void initState() {
    super.initState();

    _future = _service.listarEtapas(widget.demandId);
  }

  @override
  void dispose() {
    _service.dispose();

    super.dispose();
  }

  void _atualizar() {
    if (!mounted) return;

    setState(() {
      _future = _service.listarEtapas(widget.demandId);
    });
  }

  void _mensagem(String texto, {bool erro = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),

          backgroundColor: erro ? Colors.red.shade800 : RedesignColors.card,
        ),
      );
  }

  Future<void> _executar(
    Future<void> Function() acao,

    String mensagemSucesso,
  ) async {
    if (_executando) return;

    setState(() => _executando = true);

    try {
      await acao();

      if (!mounted) return;

      _atualizar();

      widget.onDadosAlterados();

      _mensagem(mensagemSucesso);
    } catch (erro) {
      if (!mounted) return;

      _mensagem('$erro', erro: true);
    } finally {
      if (mounted) {
        setState(() => _executando = false);
      }
    }
  }

  Future<void> _abrirFormulario({TechnicalStage? etapa}) async {
    if (_executando || !_podeAlterar) return;

    final descricao = TextEditingController(text: etapa?.descricao ?? '');

    final ordem = TextEditingController(text: etapa?.ordem.toString() ?? '');

    final formulario = GlobalKey<FormState>();

    try {
      final resultado = await showDialog<({String descricao, int? ordem})>(
        context: context,

        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: RedesignColors.card,

            title: Text(
              etapa == null ? 'Nova etapa' : 'Editar etapa',

              style: const TextStyle(color: RedesignColors.textPrimary),
            ),

            content: SizedBox(
              width: 440,

              child: Form(
                key: formulario,

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    TextFormField(
                      controller: descricao,

                      maxLength: 255,

                      maxLines: 3,

                      minLines: 1,

                      style: const TextStyle(color: RedesignColors.textPrimary),

                      decoration: const InputDecoration(
                        labelText: 'Descrição da etapa',

                        hintText: 'Descreva a atividade',
                      ),

                      validator: (valor) {
                        final texto = valor?.trim() ?? '';

                        if (texto.length < 3) {
                          return 'Informe pelo menos 3 caracteres.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: ordem,

                      keyboardType: TextInputType.number,

                      style: const TextStyle(color: RedesignColors.textPrimary),

                      decoration: InputDecoration(
                        labelText: 'Posição (opcional)',

                        helperText: etapa == null
                            ? 'Vazio: adicionar ao final'
                            : 'Posição atual: ${etapa.ordem}',
                      ),

                      validator: (valor) {
                        final texto = valor?.trim() ?? '';

                        if (texto.isEmpty) return null;

                        final numero = int.tryParse(texto);

                        if (numero == null || numero < 1) {
                          return 'Informe um número maior que zero.';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),

                child: const Text('Cancelar'),
              ),

              FilledButton(
                onPressed: () {
                  if (formulario.currentState?.validate() != true) {
                    return;
                  }

                  Navigator.pop(dialogContext, (
                    descricao: descricao.text.trim(),

                    ordem: ordem.text.trim().isEmpty
                        ? null
                        : int.parse(ordem.text.trim()),
                  ));
                },

                style: FilledButton.styleFrom(
                  backgroundColor: RedesignColors.purple,
                ),

                child: const Text('Salvar'),
              ),
            ],
          );
        },
      );

      if (resultado == null || !mounted) return;

      await _executar(
        () async {
          if (etapa == null) {
            await _service.criarEtapa(
              widget.demandId,

              descricao: resultado.descricao,

              ordem: resultado.ordem,
            );
          } else {
            await _service.editarEtapa(
              widget.demandId,

              etapa.id,

              descricao: resultado.descricao,

              ordem: resultado.ordem,
            );
          }
        },

        etapa == null
            ? 'Etapa criada com sucesso.'
            : 'Etapa atualizada com sucesso.',
      );
    } finally {
      descricao.dispose();

      ordem.dispose();
    }
  }

  Future<void> _concluir(TechnicalStage etapa) async {
    if (_executando || !_podeAlterar || etapa.concluida) return;

    final confirmar = await showDialog<bool>(
      context: context,

      builder: (dialogContext) => AlertDialog(
        backgroundColor: RedesignColors.card,

        title: const Text(
          'Concluir etapa',

          style: TextStyle(color: RedesignColors.textPrimary),
        ),

        content: Text(
          'Deseja concluir "${etapa.descricao}"?',

          style: const TextStyle(color: RedesignColors.textSecondary),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),

            child: const Text('Cancelar'),
          ),

          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),

            style: FilledButton.styleFrom(
              backgroundColor: RedesignColors.green,
            ),

            child: const Text('Concluir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await _executar(() async {
      await _service.concluirEtapa(widget.demandId, etapa.id);
    }, 'Etapa concluída com sucesso.');
  }

  Future<void> _excluir(TechnicalStage etapa) async {
    if (_executando || !_podeAlterar || etapa.concluida) return;

    final motivo = TextEditingController();

    final formulario = GlobalKey<FormState>();

    try {
      final justificativa = await showDialog<String>(
        context: context,

        builder: (dialogContext) => AlertDialog(
          backgroundColor: RedesignColors.card,

          title: const Text(
            'Excluir etapa',

            style: TextStyle(color: RedesignColors.textPrimary),
          ),

          content: SizedBox(
            width: 440,

            child: Form(
              key: formulario,

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Text(
                    etapa.descricao,

                    style: const TextStyle(color: RedesignColors.textSecondary),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: motivo,

                    maxLength: 500,

                    maxLines: 3,

                    style: const TextStyle(color: RedesignColors.textPrimary),

                    decoration: const InputDecoration(
                      labelText: 'Justificativa obrigatória',
                    ),

                    validator: (valor) {
                      final tamanho = valor?.trim().length ?? 0;

                      if (tamanho < 10 || tamanho > 500) {
                        return 'Informe de 10 a 500 caracteres.';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),

              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                if (formulario.currentState?.validate() != true) {
                  return;
                }

                Navigator.pop(dialogContext, motivo.text.trim());
              },

              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),

              child: const Text('Excluir'),
            ),
          ],
        ),
      );

      if (justificativa == null || !mounted) return;

      await _executar(
        () => _service.excluirEtapa(
          widget.demandId,

          etapa.id,

          motivo: justificativa,
        ),

        'Etapa excluída com sucesso.',
      );
    } finally {
      motivo.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: RedesignColors.card,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: RedesignColors.border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,

            crossAxisAlignment: WrapCrossAlignment.center,

            spacing: 12,

            runSpacing: 12,

            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    'Etapas operacionais',

                    style: TextStyle(
                      color: RedesignColors.textPrimary,

                      fontSize: 18,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    'Acompanhe e gerencie as atividades da demanda.',

                    style: TextStyle(
                      color: RedesignColors.textSecondary,

                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              Wrap(
                spacing: 8,

                children: [
                  IconButton(
                    tooltip: 'Atualizar etapas',

                    onPressed: _executando ? null : _atualizar,

                    icon: const Icon(
                      Icons.refresh_rounded,

                      color: RedesignColors.textSecondary,
                    ),
                  ),

                  if (_podeAlterar)
                    FilledButton.icon(
                      onPressed: _executando ? null : () => _abrirFormulario(),

                      icon: const Icon(Icons.add_rounded),

                      label: const Text('Nova etapa'),

                      style: FilledButton.styleFrom(
                        backgroundColor: RedesignColors.purple,

                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (!_podeAlterar) ...[
            const SizedBox(height: 14),

            const Text(
              'As alterações ficam disponíveis durante a execução '
              'da demanda, conforme as permissões da API.',

              style: TextStyle(
                color: RedesignColors.textSecondary,

                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 20),

          const Divider(color: RedesignColors.border),

          const SizedBox(height: 16),

          if (_executando)
            const LinearProgressIndicator(
              color: RedesignColors.purple,

              backgroundColor: RedesignColors.border,
            ),

          FutureBuilder<List<TechnicalStage>>(
            future: _future,

            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(28),

                  child: Center(
                    child: CircularProgressIndicator(
                      color: RedesignColors.purple,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Não foi possível carregar as etapas.\n'
                      '${snapshot.error}',

                      style: const TextStyle(
                        color: RedesignColors.textSecondary,

                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: _executando ? null : _atualizar,

                      icon: const Icon(Icons.refresh_rounded),

                      label: const Text('Tentar novamente'),
                    ),
                  ],
                );
              }

              final etapas = snapshot.data ?? [];

              if (etapas.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),

                  child: Center(
                    child: Text(
                      'Nenhuma etapa operacional cadastrada.',

                      style: TextStyle(color: RedesignColors.textSecondary),
                    ),
                  ),
                );
              }

              final concluidas = etapas
                  .where((etapa) => etapa.concluida)
                  .length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    '$concluidas de ${etapas.length} etapas concluídas',

                    style: const TextStyle(
                      color: RedesignColors.textSecondary,

                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 16),

                  ...etapas.map((etapa) {
                    final cor = etapa.concluida
                        ? RedesignColors.green
                        : RedesignColors.purple;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),

                      child: Container(
                        width: double.infinity,

                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: RedesignColors.background.withValues(
                            alpha: 0.55,
                          ),

                          borderRadius: BorderRadius.circular(12),

                          border: Border.all(color: RedesignColors.border),
                        ),

                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,

                          crossAxisAlignment: WrapCrossAlignment.center,

                          spacing: 14,

                          runSpacing: 12,

                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,

                              children: [
                                Icon(
                                  etapa.concluida
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked,

                                  color: cor,

                                  size: 23,
                                ),

                                const SizedBox(width: 12),

                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        etapa.descricao,

                                        style: const TextStyle(
                                          color: RedesignColors.textPrimary,

                                          fontSize: 13,

                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      const SizedBox(height: 5),

                                      Text(
                                        'Etapa ${etapa.ordem} • '
                                        '${etapa.concluida ? "Concluída" : "Pendente"}',

                                        style: TextStyle(
                                          color: cor,

                                          fontSize: 11,
                                        ),
                                      ),

                                      if (etapa.concluidaEm != null)
                                        Text(
                                          'Concluída em '
                                          '${TechnicalDemandDetailsPage._formatarData(etapa.concluidaEm)}',

                                          style: const TextStyle(
                                            color: RedesignColors.textSecondary,

                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            if (_podeAlterar && !etapa.concluida)
                              Wrap(
                                spacing: 6,

                                runSpacing: 6,

                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _executando
                                        ? null
                                        : () => _abrirFormulario(etapa: etapa),

                                    icon: const Icon(
                                      Icons.edit_outlined,

                                      size: 16,
                                    ),

                                    label: const Text('Editar'),
                                  ),

                                  OutlinedButton.icon(
                                    onPressed: _executando
                                        ? null
                                        : () => _concluir(etapa),

                                    icon: const Icon(
                                      Icons.check_rounded,

                                      size: 16,
                                    ),

                                    label: const Text('Concluir'),
                                  ),

                                  IconButton(
                                    tooltip: 'Excluir etapa',

                                    onPressed: _executando
                                        ? null
                                        : () => _excluir(etapa),

                                    icon: Icon(
                                      Icons.delete_outline_rounded,

                                      color: Colors.red.shade300,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InformationItem extends StatelessWidget {
  const _InformationItem({
    required this.label,

    required this.value,

    required this.icon,

    required this.color,
  });

  final String label;

  final String value;

  final IconData icon;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 42,

            height: 42,

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),

              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(icon, color: color, size: 21),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  label,

                  style: const TextStyle(
                    color: RedesignColors.textSecondary,

                    fontSize: 10,

                    fontWeight: FontWeight.w600,

                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  value,

                  style: const TextStyle(
                    color: RedesignColors.textPrimary,

                    fontSize: 14,

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicalHomologationAction extends StatefulWidget {
  const _TechnicalHomologationAction({super.key, required this.demandId});

  final String demandId;

  @override
  State<_TechnicalHomologationAction> createState() =>
      _TechnicalHomologationActionState();
}

class _TechnicalHomologationActionState
    extends State<_TechnicalHomologationAction> {
  final TechnicalHomologationService _homologationService =
      TechnicalHomologationService();

  final TechnicalStageService _stageService = TechnicalStageService();

  bool _carregando = true;

  bool _enviando = false;

  PedidoModel? _demanda;

  List<TechnicalStage> _etapas = [];

  String? _erro;

  @override
  void initState() {
    super.initState();

    _carregar();
  }

  @override
  void dispose() {
    _homologationService.dispose();

    _stageService.dispose();

    super.dispose();
  }

  Future<void> _carregar() async {
    if (!mounted || _enviando) return;

    setState(() {
      _carregando = true;

      _erro = null;
    });

    try {
      final demanda = await _homologationService.buscarDemanda(widget.demandId);

      final etapas = await _stageService.listarEtapas(widget.demandId);

      if (!mounted) return;

      setState(() {
        _demanda = demanda;

        _etapas = etapas;

        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _erro = erro.toString();

        _carregando = false;
      });
    }
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),

          backgroundColor: erro ? Colors.red.shade800 : RedesignColors.card,
        ),
      );
  }

  Future<void> _enviar() async {
    if (_enviando || _carregando) return;

    setState(() {
      _enviando = true;

      _erro = null;
    });

    try {
      // Reconsulta a API para não confiar em dados antigos.

      final demanda = await _homologationService.buscarDemanda(widget.demandId);

      final etapas = await _stageService.listarEtapas(widget.demandId);

      if (!mounted) return;

      setState(() {
        _demanda = demanda;

        _etapas = etapas;
      });

      if (demanda.status.trim().toUpperCase() != 'EXECUCAO') {
        _mostrarMensagem('A demanda não está mais em execução.', erro: true);

        return;
      }

      if (etapas.isEmpty) {
        _mostrarMensagem(
          'Cadastre as etapas operacionais antes de enviar '
          'a demanda para homologação.',

          erro: true,
        );

        return;
      }

      final pendentes = etapas.where((etapa) => !etapa.concluida).length;

      if (pendentes > 0) {
        _mostrarMensagem(
          'Existem $pendentes etapas pendentes. '
          'Conclua todas antes de enviar para homologação.',

          erro: true,
        );

        return;
      }

      final confirmar = await showDialog<bool>(
        context: context,

        builder: (dialogContext) => AlertDialog(
          backgroundColor: RedesignColors.card,

          title: const Text(
            'Enviar para homologação',

            style: TextStyle(color: RedesignColors.textPrimary),
          ),

          content: const Text(
            'Todas as etapas estão concluídas. '
            'Deseja enviar esta demanda para homologação '
            'do cliente?',

            style: TextStyle(color: RedesignColors.textSecondary),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),

              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),

              style: FilledButton.styleFrom(
                backgroundColor: RedesignColors.amber,

                foregroundColor: RedesignColors.background,
              ),

              child: const Text('Confirmar envio'),
            ),
          ],
        ),
      );

      if (confirmar != true || !mounted) return;

      final demandaAtualizada = await _homologationService
          .enviarParaHomologacao(widget.demandId);

      if (!mounted) return;

      setState(() {
        _demanda = demandaAtualizada;
      });

      _mostrarMensagem('Demanda enviada para homologação com sucesso.');
    } catch (erro) {
      if (!mounted) return;

      _mostrarMensagem(erro.toString(), erro: true);

      // Uma falha de rede não garante que o servidor

      // deixou de processar o envio.

      // A próxima atualização consulta o estado real.

      await _carregarAposErro();
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  Future<void> _carregarAposErro() async {
    try {
      final demanda = await _homologationService.buscarDemanda(widget.demandId);

      if (!mounted) return;

      setState(() {
        _demanda = demanda;
      });
    } catch (_) {
      // O erro original já foi exibido ao usuário.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: RedesignColors.card,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: RedesignColors.border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Envio para homologação',

            style: TextStyle(
              color: RedesignColors.textPrimary,

              fontSize: 18,

              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Após concluir todas as etapas operacionais, '
            'envie a demanda para avaliação do cliente.',

            style: TextStyle(color: RedesignColors.textSecondary, fontSize: 13),
          ),

          const SizedBox(height: 20),

          if (_carregando)
            const Center(
              child: CircularProgressIndicator(color: RedesignColors.purple),
            )
          else if (_erro != null) ...[
            Text(
              _erro!,

              style: const TextStyle(
                color: RedesignColors.textSecondary,

                fontSize: 13,
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _carregar,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Tentar novamente'),
            ),
          ] else if (_demanda != null) ...[
            Builder(
              builder: (context) {
                final status = _demanda!.status.trim().toUpperCase();

                final pendentes = _etapas
                    .where((etapa) => !etapa.concluida)
                    .length;

                final podeEnviar =
                    status == 'EXECUCAO' &&
                    _etapas.isNotEmpty &&
                    pendentes == 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Estado atual: $status',

                      style: const TextStyle(
                        color: RedesignColors.textPrimary,

                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${_etapas.length - pendentes} de '
                      '${_etapas.length} etapas concluídas',

                      style: const TextStyle(
                        color: RedesignColors.textSecondary,

                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (status == 'HOMOLOGACAO')
                      const Text(
                        'Esta demanda já foi enviada '
                        'para homologação.',

                        style: TextStyle(
                          color: RedesignColors.green,

                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (status == 'CONCLUIDO')
                      const Text(
                        'Esta demanda já foi concluída.',

                        style: TextStyle(
                          color: RedesignColors.green,

                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else ...[
                      if (status == 'EXECUCAO' && _etapas.isEmpty)
                        const Text(
                          'Cadastre pelo menos uma etapa '
                          'operacional para continuar.',

                          style: TextStyle(
                            color: RedesignColors.textSecondary,

                            fontSize: 12,
                          ),
                        ),

                      if (status == 'EXECUCAO' && pendentes > 0)
                        Text(
                          'Ainda existem $pendentes etapas '
                          'pendentes.',

                          style: const TextStyle(
                            color: RedesignColors.amber,

                            fontSize: 12,
                          ),
                        ),

                      const SizedBox(height: 12),

                      FilledButton.icon(
                        onPressed: podeEnviar && !_enviando ? _enviar : null,

                        icon: _enviando
                            ? const SizedBox(
                                width: 16,

                                height: 16,

                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),

                        label: Text(
                          _enviando ? 'Enviando...' : 'Enviar para homologação',
                        ),

                        style: FilledButton.styleFrom(
                          backgroundColor: RedesignColors.amber,

                          foregroundColor: RedesignColors.background,

                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,

                            vertical: 15,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    TextButton.icon(
                      onPressed: _enviando ? null : _carregar,

                      icon: const Icon(Icons.refresh_rounded, size: 17),

                      label: const Text('Atualizar situação'),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _TechnicalOccurrencesSection extends StatefulWidget {
  const _TechnicalOccurrencesSection({
    required this.demandId,
    required this.onDadosAlterados,
  });

  final String demandId;
  final VoidCallback onDadosAlterados;

  @override
  State<_TechnicalOccurrencesSection> createState() =>
      _TechnicalOccurrencesSectionState();
}

class _TechnicalOccurrencesSectionState
    extends State<_TechnicalOccurrencesSection> {
  final TechnicalOccurrenceService _service = TechnicalOccurrenceService();
  late Future<List<TechnicalOccurrence>> _future;
  bool _executando = false;

  @override
  void initState() {
    super.initState();
    _atualizar();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  void _atualizar() {
    if (!mounted) return;
    setState(() {
      _future = _service.listarOcorrencias(widget.demandId);
    });
  }

  void _mensagem(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: erro ? Colors.red.shade800 : RedesignColors.card,
        ),
      );
  }

  Future<void> _executar(
    Future<void> Function() acao,
    String mensagemSucesso,
  ) async {
    if (_executando) return;
    setState(() => _executando = true);
    try {
      await acao();
      if (!mounted) return;
      _atualizar();
      widget.onDadosAlterados();
      _mensagem(mensagemSucesso);
    } catch (erro) {
      if (!mounted) return;
      _mensagem(erro.toString(), erro: true);
      _atualizar(); // Reconsulta: o servidor pode ter processado a ação.
    } finally {
      if (mounted) setState(() => _executando = false);
    }
  }

  Future<void> _registrar() async {
    if (_executando) return;
    final descricao = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String tipo = 'ERRO';
    try {
      final resultado = await showDialog<({String tipo, String descricao})>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, atualizarDialogo) => AlertDialog(
            backgroundColor: RedesignColors.card,
            title: const Text(
              'Registrar ocorrência',
              style: TextStyle(color: RedesignColors.textPrimary),
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: tipo,
                        dropdownColor: RedesignColors.card,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: const [
                          DropdownMenuItem(value: 'ERRO', child: Text('Erro')),
                          DropdownMenuItem(
                            value: 'SOLICITACAO_CORRECAO',
                            child: Text('Solicitação de correção'),
                          ),
                        ],
                        onChanged: (valor) {
                          if (valor != null) {
                            atualizarDialogo(() => tipo = valor);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descricao,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          hintText:
                              'Descreva o problema ou a correção solicitada',
                        ),
                        validator: (valor) {
                          final tamanho = valor?.trim().length ?? 0;
                          if (tamanho < 10 || tamanho > 2000) {
                            return 'Informe entre 10 e 2000 caracteres.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.pop(dialogContext, (
                    tipo: tipo,
                    descricao: descricao.text.trim(),
                  ));
                },
                style: FilledButton.styleFrom(
                  backgroundColor: RedesignColors.purple,
                ),
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      );
      if (resultado == null || !mounted) return;
      await _executar(() async {
        await _service.criarOcorrencia(
          widget.demandId,
          tipo: resultado.tipo,
          descricao: resultado.descricao,
        );
      }, 'Ocorrência registrada com sucesso.');
    } finally {
      descricao.dispose();
    }
  }

  Future<void> _resolver(TechnicalOccurrence ocorrencia) async {
    if (_executando || ocorrencia.resolvida) return;
    final descricao = TextEditingController();
    final formKey = GlobalKey<FormState>();
    try {
      final resultado = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: RedesignColors.card,
          title: const Text(
            'Registrar resolução',
            style: TextStyle(color: RedesignColors.textPrimary),
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ocorrencia.descricao,
                      style: const TextStyle(
                        color: RedesignColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descricao,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'O que foi corrigido?',
                      ),
                      validator: (valor) {
                        final tamanho = valor?.trim().length ?? 0;
                        if (tamanho < 10 || tamanho > 2000) {
                          return 'Informe entre 10 e 2000 caracteres.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(dialogContext, descricao.text.trim());
              },
              style: FilledButton.styleFrom(
                backgroundColor: RedesignColors.green,
              ),
              child: const Text('Registrar resolução'),
            ),
          ],
        ),
      );
      if (resultado == null || !mounted) return;
      await _executar(() async {
        await _service.resolverOcorrencia(
          widget.demandId,
          ocorrencia.id,
          descricaoResolucao: resultado,
        );
      }, 'Correção registrada com sucesso.');
    } finally {
      descricao.dispose();
    }
  }

  String _data(DateTime? data) {
    if (data == null) return 'Data não informada';
    final local = data.toLocal();
    String dois(int numero) => numero.toString().padLeft(2, '0');
    return '${dois(local.day)}/${dois(local.month)}/${local.year} '
        '${dois(local.hour)}:${dois(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RedesignColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RedesignColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ocorrências e correções',
                    style: TextStyle(
                      color: RedesignColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Registros reais vinculados a esta demanda.',
                    style: TextStyle(
                      color: RedesignColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    tooltip: 'Atualizar ocorrências',
                    onPressed: _executando ? null : _atualizar,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: RedesignColors.textSecondary,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _executando ? null : _registrar,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Registrar ocorrência'),
                    style: FilledButton.styleFrom(
                      backgroundColor: RedesignColors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: RedesignColors.border),
          const SizedBox(height: 16),
          if (_executando)
            const LinearProgressIndicator(
              color: RedesignColors.purple,
              backgroundColor: RedesignColors.border,
            ),
          FutureBuilder<List<TechnicalOccurrence>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: RedesignColors.purple,
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Não foi possível carregar as ocorrências.\n'
                      '${snapshot.error}',
                      style: const TextStyle(
                        color: RedesignColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _atualizar,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                );
              }
              final ocorrencias = snapshot.data ?? [];
              if (ocorrencias.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Nenhuma ocorrência registrada nesta demanda.',
                    style: TextStyle(color: RedesignColors.textSecondary),
                  ),
                );
              }
              final abertas = ocorrencias
                  .where((item) => !item.resolvida)
                  .length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ocorrencias.length} ocorrência(s) • $abertas pendente(s)',
                    style: const TextStyle(
                      color: RedesignColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...ocorrencias.map((ocorrencia) {
                    final resolvida = ocorrencia.resolvida;
                    final cor = resolvida
                        ? RedesignColors.green
                        : RedesignColors.amber;
                    final tipo = ocorrencia.tipo == 'ERRO'
                        ? 'Erro'
                        : 'Solicitação de correção';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: RedesignColors.background.withValues(
                            alpha: 0.55,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RedesignColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Icon(
                                  resolvida
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.report_problem_outlined,
                                  color: cor,
                                  size: 20,
                                ),
                                Text(
                                  tipo,
                                  style: const TextStyle(
                                    color: RedesignColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  resolvida ? 'Resolvida' : 'Pendente',
                                  style: TextStyle(
                                    color: cor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ocorrencia.descricao,
                              style: const TextStyle(
                                color: RedesignColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SelectableText(
                              'Autor: ${ocorrencia.autorId}  •  ${_data(ocorrencia.createdAt)}',
                              style: const TextStyle(
                                color: RedesignColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            if (ocorrencia.statusAnterior != null ||
                                ocorrencia.statusNovo != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Estado: ${ocorrencia.statusAnterior ?? "Não informado"} '
                                '→ ${ocorrencia.statusNovo ?? "Não informado"}',
                                style: const TextStyle(
                                  color: RedesignColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            if (resolvida) ...[
                              const SizedBox(height: 14),
                              const Divider(color: RedesignColors.border),
                              const SizedBox(height: 8),
                              const Text(
                                'Resolução',
                                style: TextStyle(
                                  color: RedesignColors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                ocorrencia.descricaoResolucao ??
                                    'Descrição não informada.',
                                style: const TextStyle(
                                  color: RedesignColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Resolvida em: ${_data(ocorrencia.resolvidaEm)}'
                                '  •  Por: ${ocorrencia.resolvidaPorId ?? "Não informado"}',
                                style: const TextStyle(
                                  color: RedesignColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _executando
                                    ? null
                                    : () => _resolver(ocorrencia),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Registrar correção'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
