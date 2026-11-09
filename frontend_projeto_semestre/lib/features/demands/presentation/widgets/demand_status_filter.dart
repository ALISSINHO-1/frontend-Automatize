import 'package:flutter/material.dart';

class DemandStatusFilter extends StatelessWidget {
  const DemandStatusFilter({
    super.key,
    required this.statusSelecionado,
    required this.onStatusChanged,
  });

  final String? statusSelecionado;
  final ValueChanged<String?> onStatusChanged;

  static const List<String> estados = [
    'PLANEAMENTO',
    'EXECUCAO',
    'HOMOLOGACAO',
    'CONCLUIDO',
  ];

  static String normalizarStatus(String status) {
    final normalizado = status
        .trim()
        .toUpperCase()
        .replaceAll('Ç', 'C')
        .replaceAll('Ã', 'A')
        .replaceAll('Í', 'I')
        .replaceAll('É', 'E');

    return normalizado == 'PLANEJAMENTO' ? 'PLANEAMENTO' : normalizado;
  }

  static List<T> filtrar<T>(
    List<T> demandas,
    String? statusSelecionado,
    String Function(T) obterStatus,
  ) {
    if (statusSelecionado == null || statusSelecionado == 'TODOS') {
      return demandas;
    }

    return demandas.where((demanda) {
      return normalizarStatus(obterStatus(demanda)) ==
          normalizarStatus(statusSelecionado);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(statusSelecionado ?? 'TODOS'),
      initialValue: statusSelecionado ?? 'TODOS',
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Filtrar por estado',
        floatingLabelBehavior: FloatingLabelBehavior.never,
        prefixIcon: Icon(Icons.filter_list),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem<String>(
          value: 'TODOS',
          child: Text('Todos os estados'),
        ),
        DropdownMenuItem<String>(
          value: 'PLANEAMENTO',
          child: Text('Planejamento'),
        ),
        DropdownMenuItem<String>(value: 'EXECUCAO', child: Text('Execução')),
        DropdownMenuItem<String>(
          value: 'HOMOLOGACAO',
          child: Text('Homologação'),
        ),
        DropdownMenuItem<String>(value: 'CONCLUIDO', child: Text('Concluído')),
      ],
      onChanged: (valor) {
        onStatusChanged(valor == 'TODOS' ? null : valor);
      },
    );
  }
}
