import 'package:flutter/material.dart';

import '../../../shared/widgets/main_layout.dart';

/// Tons do preview do Stitch para a área administrativa. Os neutros vêm de
/// [AutomatizeColors]; aqui ficam só o roxo de destaque e as cores por estado.
abstract final class AdminStyle {
  static const fundo = AutomatizeColors.background;
  static const card = AutomatizeColors.panel;
  static const cardBorda = AutomatizeColors.border;
  static const destaque = AutomatizeColors.primary;
  static const destaqueClaro = AutomatizeColors.cyan;

  static Color corEstado(String status) => switch (normalizar(status)) {
    'PLANEAMENTO' => AutomatizeColors.purple,
    'EXECUCAO' => AutomatizeColors.primary,
    'HOMOLOGACAO' => AutomatizeColors.warning,
    'CONCLUIDO' => AutomatizeColors.success,
    _ => AutomatizeColors.muted,
  };

  static String rotuloEstado(String status) => switch (normalizar(status)) {
    'PLANEAMENTO' => 'PLANEJAMENTO',
    'EXECUCAO' => 'EXECUÇÃO',
    'HOMOLOGACAO' => 'HOMOLOGAÇÃO',
    'CONCLUIDO' => 'CONCLUÍDO',
    final outro => outro,
  };

  // A HML antiga usava PLANEJAMENTO; o backend persiste PLANEAMENTO.
  static String normalizar(String status) {
    final s = status.trim().toUpperCase();
    return s == 'PLANEJAMENTO' ? 'PLANEAMENTO' : s;
  }

  static BoxDecoration caixa({Color? borda}) => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borda ?? cardBorda),
  );

  static const titulo = TextStyle(
    color: AutomatizeColors.text,
    fontSize: 28,
    fontWeight: FontWeight.w800,
  );
  static const subtitulo = TextStyle(
    color: AutomatizeColors.muted,
    fontSize: 14,
  );
  static const tituloCard = TextStyle(
    color: AutomatizeColors.text,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static String data(DateTime? data, {bool hora = false}) {
    if (data == null) return 'Não informado';
    final l = data.toLocal();
    String d(int n) => n.toString().padLeft(2, '0');
    final dia = '${d(l.day)}/${d(l.month)}/${l.year}';
    return hora ? '$dia às ${d(l.hour)}:${d(l.minute)}' : dia;
  }
}

/// Selo de estado (pílula colorida) igual ao do preview.
class EstadoChip extends StatelessWidget {
  const EstadoChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final cor = AdminStyle.corEstado(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.45)),
      ),
      child: Text(
        AdminStyle.rotuloEstado(status),
        style: TextStyle(
          color: cor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
