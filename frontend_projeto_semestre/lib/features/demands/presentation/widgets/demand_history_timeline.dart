import 'package:flutter/material.dart';

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
        color: const Color(0xFF181C24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF424754)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Histórico de estados',
            style: TextStyle(
              color: Color(0xFFDFE2EE),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acompanhe as alterações de estado da demanda.',
            style: TextStyle(color: Color(0xFFC2C6D6), fontSize: 14),
          ),
          const SizedBox(height: 28),

          if (carregando)
            const Center(child: CircularProgressIndicator())
          else if (erro != null)
            Text(erro!, style: const TextStyle(color: Color(0xFFFF9C9C)))
          else if (eventos.isEmpty)
            const Text(
              'Nenhuma alteração de estado registrada.',
              style: TextStyle(color: Color(0xFFC2C6D6), fontSize: 14),
            )
          else
            ...List.generate(eventos.length, (index) {
              final evento = eventos[index];
              final ultimo = index == eventos.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4D8EFF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFADC6FF),
                              width: 2,
                            ),
                          ),
                        ),
                        if (!ultimo)
                          Container(
                            width: 2,
                            height: 28,
                            color: const Color(0xFF424754),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: ultimo ? 0 : 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${evento.estadoAnterior ?? "Início"}'
                            ' → ${evento.novoEstado}',
                            style: const TextStyle(
                              color: Color(0xFFDFE2EE),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            evento.usuarioResponsavel,
                            style: const TextStyle(
                              color: Color(0xFFADC6FF),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatarData(evento.dataHora),
                            style: const TextStyle(
                              color: Color(0xFF8C909F),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}
