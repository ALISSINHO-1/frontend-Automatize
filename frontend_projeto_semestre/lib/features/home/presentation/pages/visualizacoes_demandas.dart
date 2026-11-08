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
    this.tecnicoId,
    this.mover,
  });

  final List<DemandaItem> demandas;
  final List<String> estados;
  final String Function(String) rotuloEstado;
  final Color Function(String) corEstado;
  final ValueChanged<DemandaItem> abrir;
  final String? tecnicoId;
  final void Function(DemandaItem, String, String)? mover;

  static const _transicoes = {
    'Planejamento': (
      origem: 'PLANEAMENTO',
      destino: 'EXECUCAO',
      coluna: 'Execução',
    ),
    'Execução': (
      origem: 'EXECUCAO',
      destino: 'HOMOLOGACAO',
      coluna: 'Homologação',
    ),
  };

  bool _podeMover(DemandaItem demanda) =>
      mover != null &&
      tecnicoId != null &&
      demanda.responsavelId == tecnicoId &&
      _transicoes.containsKey(rotuloEstado(demanda.estado));

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final estado in estados)
          SizedBox(
            width: 265,
            child: DragTarget<DemandaItem>(
              onWillAcceptWithDetails: (dados) =>
                  _podeMover(dados.data) &&
                  _transicoes[rotuloEstado(dados.data.estado)]?.coluna ==
                      estado,
              onAcceptWithDetails: (dados) => _avancar(dados.data),
              builder: (context, candidatos, _) {
                final itens = demandas
                    .where((d) => rotuloEstado(d.estado) == estado)
                    .toList();
                return Card(
                  color: candidatos.isEmpty
                      ? AutomatizeColors.panel
                      : AutomatizeColors.panelLight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          estado,
                          style: TextStyle(color: corEstado(estado)),
                        ),
                        trailing: Text('${itens.length}'),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: itens.length,
                          itemBuilder: (context, index) =>
                              _cartao(context, itens[index]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    ),
  );

  void _avancar(DemandaItem demanda) {
    if (!_podeMover(demanda)) return;
    final transicao = _transicoes[rotuloEstado(demanda.estado)]!;
    mover!(demanda, transicao.origem, transicao.destino);
  }

  Widget _cartao(BuildContext context, DemandaItem demanda) {
    final podeMover = _podeMover(demanda);
    final tile = ListTile(
      title: Text(demanda.titulo),
      subtitle: Text(
        demanda.dataPrevisao == null
            ? demanda.codigo
            : '${demanda.codigo} · ${MaterialLocalizations.of(context).formatCompactDate(demanda.dataPrevisao!)}',
      ),
      onTap: () => abrir(demanda),
      trailing: podeMover
          ? IconButton(
              tooltip:
                  'Avançar para ${_transicoes[rotuloEstado(demanda.estado)]!.coluna}',
              onPressed: () => _avancar(demanda),
              icon: const Icon(Icons.arrow_forward),
            )
          : null,
    );
    if (!podeMover) return tile;
    final feedback = Material(
      color: AutomatizeColors.panelLight,
      borderRadius: BorderRadius.circular(12),
      elevation: 6,
      child: SizedBox(
        width: 245,
        child: ListTile(
          title: Text(demanda.titulo),
          subtitle: Text(demanda.codigo),
        ),
      ),
    );
    final child = Opacity(opacity: 0.4, child: tile);
    if (Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      return LongPressDraggable<DemandaItem>(
        data: demanda,
        feedback: feedback,
        childWhenDragging: child,
        maxSimultaneousDrags: 1,
        child: tile,
      );
    }
    return Draggable<DemandaItem>(
      data: demanda,
      feedback: feedback,
      childWhenDragging: child,
      maxSimultaneousDrags: 1,
      child: tile,
    );
  }
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
