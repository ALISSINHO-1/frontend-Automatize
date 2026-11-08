import 'package:flutter/material.dart';

import '../../../../shared/widgets/main_layout.dart';
import 'demanda_store.dart';

List<({String rotulo, DateTime? data})> datasDaDemanda(DemandaItem demanda) => [
  (rotulo: 'Início', data: demanda.dataInicio),
  (rotulo: 'Previsão', data: demanda.dataPrevisao),
  (rotulo: 'Conclusão', data: demanda.dataConclusao),
];

class QuadroDemandas extends StatelessWidget {
  const QuadroDemandas({
    super.key,
    required this.demandas,
    required this.estados,
    required this.rotuloEstado,
    required this.corEstado,
    required this.abrir,
  });

  final List<DemandaItem> demandas;
  final List<String> estados;
  final String Function(String) rotuloEstado;
  final Color Function(String) corEstado;
  final ValueChanged<DemandaItem> abrir;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final estado in estados)
          SizedBox(
            width: 265,
            child: Card(
              color: AutomatizeColors.panel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(
                      estado,
                      style: TextStyle(color: corEstado(estado)),
                    ),
                    trailing: Text(
                      '${demandas.where((d) => rotuloEstado(d.estado) == estado).length}',
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final demanda in demandas.where(
                          (d) => rotuloEstado(d.estado) == estado,
                        ))
                          ListTile(
                            title: Text(demanda.titulo),
                            subtitle: Text(
                              demanda.dataPrevisao == null
                                  ? demanda.codigo
                                  : '${demanda.codigo} · ${MaterialLocalizations.of(context).formatCompactDate(demanda.dataPrevisao!)}',
                            ),
                            onTap: () => abrir(demanda),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class CalendarioDemandas extends StatefulWidget {
  const CalendarioDemandas({
    super.key,
    required this.demandas,
    required this.abrir,
  });

  final List<DemandaItem> demandas;
  final ValueChanged<DemandaItem> abrir;

  @override
  State<CalendarioDemandas> createState() => _CalendarioDemandasState();
}

class _CalendarioDemandasState extends State<CalendarioDemandas> {
  DateTime _dia = DateUtils.dateOnly(DateTime.now());

  void _mudarMes(int passo) {
    setState(() => _dia = DateTime(_dia.year, _dia.month + passo));
  }

  @override
  Widget build(BuildContext context) {
    final idioma = MaterialLocalizations.of(context);
    final eventos = <DateTime, List<({DemandaItem demanda, String rotulo})>>{};
    for (final demanda in widget.demandas) {
      for (final evento in datasDaDemanda(demanda)) {
        final data = evento.data;
        if (data == null) continue;
        (eventos[DateUtils.dateOnly(data)] ??= []).add((
          demanda: demanda,
          rotulo: evento.rotulo,
        ));
      }
    }
    final primeiro = DateTime(_dia.year, _dia.month);
    final deslocamento =
        (primeiro.weekday % 7 - idioma.firstDayOfWeekIndex + 7) % 7;
    final totalDias = DateUtils.getDaysInMonth(_dia.year, _dia.month);
    final doDia = eventos[_dia] ?? const [];
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Card(
            color: AutomatizeColors.panel,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Mês anterior',
                        onPressed: () => _mudarMes(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          idioma.formatMonthYear(_dia),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Próximo mês',
                        onPressed: () => _mudarMes(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Text(
                            idioma.narrowWeekdays[(idioma.firstDayOfWeekIndex +
                                    i) %
                                7],
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisExtent: 48,
                        ),
                    itemCount: deslocamento + totalDias,
                    itemBuilder: (context, index) {
                      if (index < deslocamento) return const SizedBox.shrink();
                      final dia = DateTime(
                        _dia.year,
                        _dia.month,
                        index - deslocamento + 1,
                      );
                      final total = eventos[dia]?.length ?? 0;
                      return Tooltip(
                        message:
                            '${idioma.formatCompactDate(dia)} · $total evento(s)',
                        child: InkWell(
                          onTap: () => setState(() => _dia = dia),
                          child: ColoredBox(
                            color: dia == _dia
                                ? AutomatizeColors.panelLight
                                : Colors.transparent,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${dia.day}'),
                                if (total > 0)
                                  Text(
                                    '$total',
                                    style: const TextStyle(
                                      color: AutomatizeColors.cyan,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(title: Text(idioma.formatCompactDate(_dia))),
                  if (doDia.isEmpty)
                    const ListTile(
                      subtitle: Text('Sem marcos registrados neste dia.'),
                    ),
                  for (final evento in doDia)
                    ListTile(
                      title: Text(evento.demanda.titulo),
                      subtitle: Text(
                        '${evento.rotulo} · ${evento.demanda.codigo}',
                      ),
                      onTap: () => widget.abrir(evento.demanda),
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
