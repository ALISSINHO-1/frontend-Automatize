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
    this.nomeResponsavel,
  });

  final List<DemandaItem> demandas;
  final List<String> estados;
  final String Function(String) rotuloEstado;
  final Color Function(String) corEstado;
  final ValueChanged<DemandaItem> abrir;
  final String? tecnicoId;
  final String Function(String?)? nomeResponsavel;
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, medidas) {
      if (estados.isEmpty) return const SizedBox.shrink();
      final largura = (medidas.maxWidth / estados.length)
          .clamp(245.0, 340.0)
          .toDouble();
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final estado in estados)
              SizedBox(width: largura, child: _coluna(estado)),
          ],
        ),
      );
    },
  );

  Widget _coluna(String estado) => DragTarget<DemandaItem>(
    onWillAcceptWithDetails: (dados) =>
        _podeMover(dados.data) &&
        _transicoes[rotuloEstado(dados.data.estado)]?.coluna == estado,
    onAcceptWithDetails: (dados) => _avancar(dados.data),
    builder: (context, candidatos, _) {
      final itens = demandas
          .where((d) => rotuloEstado(d.estado) == estado)
          .toList();
      final cor = corEstado(estado);
      return Card(
        clipBehavior: Clip.antiAlias,
        color: candidatos.isNotEmpty
            ? AutomatizeColors.panelLight
            : cor.withValues(alpha: .075),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cor.withValues(alpha: .32)),
        ),
        child: ListView.builder(
          itemCount: itens.isEmpty ? 3 : itens.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                tileColor: cor.withValues(alpha: .15),
                title: Text(
                  estado,
                  style: TextStyle(color: cor, fontWeight: FontWeight.w800),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AutomatizeColors.background.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${itens.length}'),
                ),
              );
            }
            if (index == 1) return const Divider(height: 1);
            if (itens.isEmpty) {
              return const ListTile(
                title: Text(
                  'Nenhuma demanda',
                  style: TextStyle(color: AutomatizeColors.muted, fontSize: 12),
                ),
              );
            }
            return _cartao(context, itens[index - 2]);
          },
        ),
      );
    },
  );

  void _avancar(DemandaItem demanda) {
    if (!_podeMover(demanda)) return;
    final transicao = _transicoes[rotuloEstado(demanda.estado)]!;
    mover!(demanda, transicao.origem, transicao.destino);
  }

  Widget _cartao(BuildContext context, DemandaItem demanda) {
    final podeMover = _podeMover(demanda);
    final nome =
        nomeResponsavel?.call(demanda.responsavelId) ??
        (demanda.responsavelId == null ? null : 'Técnico atribuído');
    final cor = corEstado(rotuloEstado(demanda.estado));
    final progresso = demanda.progresso.clamp(0.0, 100.0);
    final prazo = demanda.dataPrevisao;
    final tile = Card(
      margin: const EdgeInsets.fromLTRB(8, 9, 8, 0),
      color: const Color(0xFF142C49),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: AutomatizeColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => abrir(demanda),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      demanda.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (podeMover)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip:
                          'Avançar para ${_transicoes[rotuloEstado(demanda.estado)]!.coluna}',
                      onPressed: () => _avancar(demanda),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                demanda.codigo,
                style: const TextStyle(
                  color: AutomatizeColors.cyan,
                  fontSize: 11,
                ),
              ),
              if (prazo != null || nome != null) ...[
                const SizedBox(height: 10),
                Text(
                  [
                    if (prazo != null)
                      'Prazo ${MaterialLocalizations.of(context).formatCompactDate(prazo)}',
                    ?nome,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AutomatizeColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
              if (demanda.progressoInformado) ...[
                const SizedBox(height: 10),
                Text(
                  '${progresso.toStringAsFixed(1).replaceAll('.', ',')}%',
                  style: const TextStyle(
                    color: AutomatizeColors.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  minHeight: 5,
                  value: progresso / 100,
                  color: cor,
                  backgroundColor: AutomatizeColors.background,
                  borderRadius: BorderRadius.circular(10),
                  semanticsLabel: 'Progresso',
                ),
              ],
            ],
          ),
        ),
      ),
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
  static const _meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  static const _diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
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
    final deslocamento = primeiro.weekday % 7;
    final totalDias = DateUtils.getDaysInMonth(_dia.year, _dia.month);
    final doDia = eventos[_dia] ?? const [];
    return LayoutBuilder(
      builder: (context, area) {
        final compacto = area.maxWidth < 480;
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Card(
                color: AutomatizeColors.panel,
                child: Padding(
                  padding: EdgeInsets.all(compacto ? 8 : 20),
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
                              '${_meses[_dia.month - 1][0].toUpperCase()}${_meses[_dia.month - 1].substring(1)} ${_dia.year}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
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
                          for (final diaSemana in _diasSemana)
                            Expanded(
                              child: Text(
                                diaSemana,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AutomatizeColors.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisExtent: compacto ? 48 : 62,
                        ),
                        itemCount: deslocamento + totalDias,
                        itemBuilder: (context, index) {
                          if (index < deslocamento)
                            return const SizedBox.shrink();
                          final dia = DateTime(
                            _dia.year,
                            _dia.month,
                            index - deslocamento + 1,
                          );
                          final total = eventos[dia]?.length ?? 0;
                          final hoje = DateUtils.isSameDay(dia, DateTime.now());
                          final selecionado = DateUtils.isSameDay(dia, _dia);
                          return Tooltip(
                            message:
                                '${idioma.formatCompactDate(dia)} · $total evento(s)',
                            child: InkWell(
                              onTap: () => setState(() => _dia = dia),
                              child: Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: selecionado
                                      ? AutomatizeColors.primary.withValues(
                                          alpha: .22,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: hoje
                                        ? AutomatizeColors.cyan
                                        : selecionado
                                        ? AutomatizeColors.primary
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${dia.day}',
                                      style: TextStyle(
                                        fontWeight: hoje || selecionado
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    if (total > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AutomatizeColors.cyan
                                              .withValues(alpha: .14),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          total > 9 ? '9+' : '$total',
                                          style: const TextStyle(
                                            color: AutomatizeColors.cyan,
                                            fontSize: 10,
                                          ),
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
      },
    );
  }
}
