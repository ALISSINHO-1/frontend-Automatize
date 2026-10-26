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
    return status
        .trim()
        .toUpperCase()
        .replaceAll('PLANEJAMENTO', 'PLANEAMENTO')
        .replaceAll('Ç', 'C')
        .replaceAll('Ã', 'A')
        .replaceAll('Í', 'I')
        .replaceAll('É', 'E');
  }

  static List<T> filtrar<T>(
    List<T> demandas,
    String? statusSelecionado,
    String Function(T) obterStatus,
  ) {
    if (statusSelecionado == null) {
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
      initialValue: statusSelecionado,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Filtrar por estado',
        floatingLabelBehavior: FloatingLabelBehavior.never,
        prefixIcon: Icon(Icons.filter_list),
        border: OutlineInputBorder(),
      ),
      hint: const Text('Todos os estados'),
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
