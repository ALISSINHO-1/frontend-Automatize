
import 'package:flutter/material.dart';

import '../../../../core/theme/redesign_colors.dart';

class DemandStatusDashboard extends StatelessWidget {
  final Map<String, int> contagens;

  const DemandStatusDashboard({
    super.key,
    required this.contagens,
  });

  @override
  Widget build(BuildContext context) {
    final indicadores = [
      (
        'Planejamento',
        'PLANEJAMENTO',
        Icons.calendar_month_outlined,
        RedesignColors.purple,
      ),
      (
        'Execução',
        'EXECUCAO',
        Icons.build_outlined,
        RedesignColors.primary,
      ),
      (
        'Homologação',
        'HOMOLOGACAO',
        Icons.fact_check_outlined,
        RedesignColors.amber,
      ),
      (
        'Concluído',
        'CONCLUIDO',
        Icons.check_circle_outline,
        RedesignColors.green,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;

        final colunas = largura >= 900
            ? 4
            : largura >= 500
                ? 2
                : 1;

        final larguraCard =
            (largura - (colunas - 1) * 16) / colunas;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: indicadores.map((indicador) {
            return SizedBox(
              width: larguraCard,
              child: _StatusCard(
                titulo: indicador.$1,
                quantidade: contagens[indicador.$2] ?? 0,
                icone: indicador.$3,
                cor: indicador.$4,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatusCard extends StatefulWidget {
  final String titulo;
  final int quantidade;
  final IconData icone;
  final Color cor;

  const _StatusCard({
    required this.titulo,
    required this.quantidade,
    required this.icone,
    required this.cor,
  });

  @override
  State<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<_StatusCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.025 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 160,
          decoration: BoxDecoration(
            color: RedesignColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.cor.withValues(
                alpha: _hovered ? 0.75 : 0.30,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.cor.withValues(
                  alpha: _hovered ? 0.16 : 0.05,
                ),
                blurRadius: _hovered ? 28 : 14,
                spreadRadius: _hovered ? 1 : 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                // Iluminação decorativa no canto inferior.
                Positioned(
                  right: -45,
                  bottom: -85,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.cor.withValues(alpha: 0.18),
                          widget.cor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Linha colorida na parte inferior.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.cor.withValues(alpha: 0),
                          widget.cor.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // Ícone iluminado.
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: widget.cor.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          widget.icone,
                          color: widget.cor,
                          size: 23,
                        ),
                      ),

                      const Spacer(),

                      // Quantidade.
                      Text(
                        '${widget.quantidade}',
                        style: const TextStyle(
                          color: RedesignColors.textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),

                      const SizedBox(height: 7),

                      // Nome do indicador.
                      Text(
                        widget.titulo,
                        style: const TextStyle(
                          color: RedesignColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pequeno gráfico decorativo.
                Positioned(
                  right: 20,
                  bottom: 19,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _barra(6),
                      const SizedBox(width: 3),
                      _barra(11),
                      const SizedBox(width: 3),
                      _barra(17),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _barra(double altura) {
    return Container(
      width: 4,
      height: altura,
      decoration: BoxDecoration(
        color: widget.cor.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
