import 'package:flutter/material.dart';

class DemandStatusDashboard extends StatelessWidget {
  final Map<String, int> contagens;

  const DemandStatusDashboard({super.key, required this.contagens});

  @override
  Widget build(BuildContext context) {
    final indicadores = [
      ('Planejamento', 'PLANEJAMENTO', Icons.edit_calendar_outlined),
      ('Execução', 'EXECUCAO', Icons.build_outlined),
      ('Homologação', 'HOMOLOGACAO', Icons.fact_check_outlined),
      ('Concluído', 'CONCLUIDO', Icons.check_circle_outline),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Painel administrativo',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final largura = constraints.maxWidth;
            final colunas = largura >= 900
                ? 4
                : largura >= 500
                ? 2
                : 1;
            final larguraCard = (largura - (colunas - 1) * 16) / colunas;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: indicadores.map((indicador) {
                return SizedBox(
                  width: larguraCard,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(indicador.$3, size: 28),
                          const SizedBox(height: 16),
                          Text(
                            '${contagens[indicador.$2] ?? 0}',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(indicador.$1),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
