
import 'package:flutter/material.dart';

import '../../../../core/theme/redesign_colors.dart';
import '../../data/models/historico_estado_model.dart';

class DemandHistoryTimeline extends StatelessWidget {
  const DemandHistoryTimeline({
    super.key,
    required this.historico,
    this.carregando = false,
    this.erro,
  });

  final List<HistoricoEstadoModel> historico;
  final bool carregando;
  final String? erro;

  String _formatarData(DateTime data) {
    final local = data.toLocal();

    String doisDigitos(int valor) => valor.toString().padLeft(2, '0');

    return '${doisDigitos(local.day)}/'
        '${doisDigitos(local.month)}/'
        '${local.year} às '
        '${doisDigitos(local.hour)}:'
        '${doisDigitos(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final eventos = [...historico]
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));

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
          const Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: RedesignColors.purple,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Histórico de estados',
                  style: TextStyle(
                    color: RedesignColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Acompanhe as alterações de estado da demanda.',
            style: TextStyle(
              color: RedesignColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),

          if (carregando)
            const Center(
              child: CircularProgressIndicator(
                color: RedesignColors.purple,
              ),
            )
          else if (erro != null)
            Text(
              erro!,
              style: const TextStyle(color: Color(0xFFFF9C9C)),
            )
          else if (eventos.isEmpty)
            const Text(
              'Nenhuma alteração de estado registrada.',
              style: TextStyle(
                color: RedesignColors.textSecondary,
                fontSize: 13,
              ),
            )
          else
            ...List.generate(eventos.length, (index) {
              final evento = eventos[index];
              final ultimo = index == eventos.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 20,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: RedesignColors.purple,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: RedesignColors.textPrimary,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: RedesignColors.purple
                                      .withValues(alpha: 0.25),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          if (!ultimo)
                            Expanded(
                              child: Container(
                                width: 2,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                color: RedesignColors.border,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: ultimo ? 0 : 26,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${evento.estadoAnterior ?? "Início"}'
                              ' → ${evento.novoEstado}',
                              style: const TextStyle(
                                color: RedesignColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              evento.usuarioResponsavel,
                              style: const TextStyle(
                                color: RedesignColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatarData(evento.dataHora),
                              style: const TextStyle(
                                color: RedesignColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
