
import 'package:flutter/material.dart';

import '../../../../core/theme/redesign_colors.dart';
import '../../data/models/pedido_model.dart';
import '../../data/models/historico_estado_model.dart';
import '../widgets/demand_history_timeline.dart';
import 'demand_attachments_page.dart';
import 'demand_homologation_page.dart';

class DemandDetailsPage extends StatelessWidget {
  const DemandDetailsPage({
    super.key,
    required this.demandId,
    this.pedido,
  });

  final String demandId;
  final PedidoModel? pedido;

  String get nomeResponsavel {
    final responsavelId = pedido?.responsavelId;

    if (responsavelId == null || responsavelId.isEmpty) {
      return 'Não atribuído';
    }

    return 'ID: $responsavelId';
  }

  static String _formatarData(DateTime? data) {
    if (data == null) return 'Não informado';

    final local = data.toLocal();

    String doisDigitos(int valor) =>
        valor.toString().padLeft(2, '0');

    return '${doisDigitos(local.day)}/'
        '${doisDigitos(local.month)}/'
        '${local.year}';
  }

  Color _corStatus(String status) {
    switch (status.trim().toUpperCase()) {
      case 'PLANEJAMENTO':
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
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                    ),
                    label: const Text('Minhas demandas'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          RedesignColors.textSecondary,
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
                      border: Border.all(
                        color: RedesignColors.border,
                      ),
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
                          pedido?.descricao ??
                              'Descrição não disponível.',
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
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
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
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
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

                  // Acesso aos anexos.
                  FilledButton.icon(
                    onPressed: pedido == null
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DemandAttachmentsPage(
                                  pedido: pedido!,
                                ),
                              ),
                            );
                          },
                    icon: const Icon(
                      Icons.attach_file_rounded,
                      size: 18,
                    ),
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

                  // Histórico demonstrativo existente.
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

                  // Homologação disponível apenas no estado correto.
                  if (pedido?.status.toUpperCase() ==
                      'HOMOLOGACAO') ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DemandHomologationPage(
                              pedido: pedido!,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.fact_check_outlined,
                        size: 18,
                      ),
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

                  // Informação sobre a integração futura.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: RedesignColors.purple
                          .withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: RedesignColors.border,
                      ),
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
                            'As informações exibidas correspondem '
                            'aos dados disponíveis para esta demanda. '
                            'Dados adicionais serão apresentados '
                            'quando disponibilizados pela API.',
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
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
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
