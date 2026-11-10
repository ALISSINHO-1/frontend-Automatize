import 'package:flutter/material.dart';

import '../../data/services/cliente_demanda_detalhes_service.dart';
import 'anexos_homologacao_card.dart';

/// Painel de acompanhamento do cliente. Utiliza exclusivamente dados da API.
class ClienteDemandaOverview extends StatefulWidget {
  const ClienteDemandaOverview({
    super.key,
    required this.dados,
    required this.demandaId,
    required this.onOcorrencias,
    this.onAvaliar,
  });

  final ClienteDemandaDetalhes dados;
  final String demandaId;
  final VoidCallback onOcorrencias;
  final VoidCallback? onAvaliar;

  @override
  State<ClienteDemandaOverview> createState() => _ClienteDemandaOverviewState();
}

class _ClienteDemandaOverviewState extends State<ClienteDemandaOverview> {
  static const _fundo = Color(0xFF0D1320);
  static const _painel = Color(0xFF161F2F);
  static const _borda = Color(0xFF2A3950);
  static const _texto = Color(0xFFE9F0FC);
  static const _muted = Color(0xFFA5B5CB);
  static const _azul = Color(0xFF77A9FF);
  static const _verde = Color(0xFF5DD6A5);
  static const _ambar = Color(0xFFFFCE81);

  int _aba = 0;

  @override
  void didUpdateWidget(covariant ClienteDemandaOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.demandaId != widget.demandaId) {
      _aba = 0;
    }
  }

  static String _campo(Object? value, {String vazio = 'Não informado'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? vazio : text;
  }

  static String _data(Object? value) {
    if (value == null) return 'Não informada';
    final data = DateTime.tryParse(value.toString());
    if (data == null) return 'Não informada';
    final local = data.toLocal();
    String dois(int valor) => valor.toString().padLeft(2, '0');
    return '${dois(local.day)}/${dois(local.month)}/${local.year}';
  }

  static String _dataHora(Object? value) {
    if (value == null) return 'Data não informada';
    final data = DateTime.tryParse(value.toString());
    if (data == null) return 'Data não informada';
    final local = data.toLocal();
    String dois(int valor) => valor.toString().padLeft(2, '0');
    return '${dois(local.day)}/${dois(local.month)}/${local.year} às ${dois(local.hour)}:${dois(local.minute)}';
  }

  static double? _progresso(Object? value) {
    if (value == null) return null;
    final numero = double.tryParse(value.toString());
    return numero?.clamp(0.0, 100.0).toDouble();
  }

  static int _ordem(Map<String, dynamic> etapa) {
    final numero = etapa['ordem'];
    if (numero is num) return numero.toInt();
    return int.tryParse(numero?.toString() ?? '') ?? 0;
  }

  static int _posicao(String status) {
    switch (status.toUpperCase().trim()) {
      case 'PLANEJAMENTO':
        return 0;
      case 'EXECUCAO':
        return 1;
      case 'HOMOLOGACAO':
        return 2;
      case 'CONCLUIDO':
        return 3;
      default:
        return -1;
    }
  }

  static String _status(String status) {
    switch (status.toUpperCase().trim()) {
      case 'PLANEJAMENTO':
        return 'Planejamento';
      case 'EXECUCAO':
        return 'Em execução';
      case 'HOMOLOGACAO':
        return 'Em homologação';
      case 'CONCLUIDO':
        return 'Concluído';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  static String _evento(String acao) {
    switch (acao.toUpperCase().trim()) {
      case 'CRIACAO_DEMANDA':
        return 'Demanda criada';
      case 'ATRIBUICAO_RESPONSAVEL':
        return 'Responsável atribuído';
      case 'ALTERACAO_ESTADO':
        return 'Status atualizado';
      case 'CADASTRO_ETAPA':
        return 'Etapa adicionada';
      case 'CONCLUSAO_ETAPA':
        return 'Etapa concluída';
      case 'REGISTRO_ACEITE':
      case 'ACEITE_DEMANDA':
        return 'Aceite registrado';
      case 'REJEICAO_DEMANDA':
        return 'Correções solicitadas';
      default:
        final texto = acao.trim().replaceAll('_', ' ').toLowerCase();
        if (texto.isEmpty) return 'Atualização da demanda';
        return texto[0].toUpperCase() + texto.substring(1);
    }
  }

  Widget _surface({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _painel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borda),
      ),
      child: child,
    );
  }

  Widget _tituloSecao(String titulo, {String? subtitulo}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(
          color: _texto, fontSize: 19, fontWeight: FontWeight.w700,
        )),
        if (subtitulo != null) ...[
          const SizedBox(height: 7),
          Text(subtitulo, style: const TextStyle(color: _muted, height: 1.4)),
        ],
      ],
    );
  }

  Widget _botaoAcao({
    required IconData icon,
    required String texto,
    required VoidCallback onPressed,
    bool primario = false,
  }) {
    if (primario) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(texto),
        style: FilledButton.styleFrom(
          backgroundColor: _azul,
          foregroundColor: _fundo,
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(texto),
      style: OutlinedButton.styleFrom(
        foregroundColor: _texto,
        side: const BorderSide(color: _borda),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _cabecalho(Map<String, dynamic> demanda, String status) {
    final codigo = _campo(demanda['codigo_identificador']);
    final homologacao = _posicao(status) == 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MINHAS DEMANDAS  /  ACOMPANHAMENTO',
            style: TextStyle(
              color: _azul, fontSize: 11, letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 9,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(_campo(demanda['titulo'], vazio: 'Demanda sem título'),
              style: const TextStyle(
                color: _texto, fontSize: 29, fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: homologacao
                    ? const Color(0xFF3E3324) : const Color(0xFF203A46),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8,
                    color: homologacao ? _ambar : _verde),
                  const SizedBox(width: 7),
                  Text(_status(status), style: TextStyle(
                    color: homologacao ? _ambar : _verde,
                    fontWeight: FontWeight.w700,
                  )),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Código ' + codigo + '   •   Criada em ' + _data(demanda['created_at']),
          style: const TextStyle(color: _muted, fontSize: 13)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: [
            if (widget.onAvaliar != null)
              _botaoAcao(icon: Icons.fact_check_outlined,
                texto: 'Avaliar entrega', onPressed: widget.onAvaliar!,
                primario: true),
            _botaoAcao(icon: Icons.report_problem_outlined,
              texto: 'Ocorrências', onPressed: widget.onOcorrencias),
          ],
        ),
      ],
    );
  }

  Widget _indicador({
    required String label,
    required String value,
    required IconData icon,
    double? valorProgresso,
  }) {
    return _surface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: _azul, size: 18),
            const SizedBox(width: 9),
            Expanded(child: Text(label, style: const TextStyle(
              color: _muted, fontSize: 12, fontWeight: FontWeight.w600,
            ))),
          ]),
          const SizedBox(height: 13),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _texto, fontSize: 20, fontWeight: FontWeight.w800,
            )),
          if (valorProgresso != null) ...[
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 6, value: valorProgresso / 100,
                backgroundColor: _borda, valueColor:
                  const AlwaysStoppedAnimation<Color>(_azul),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _indicadores(Map<String, dynamic> demanda, String status,
      double? progresso) {
    return LayoutBuilder(builder: (context, constraints) {
      final largura = constraints.maxWidth;
      final colunas = largura >= 980 ? 4 : largura >= 400 ? 2 : 1;
      final larguraCard = (largura - (colunas - 1) * 12) / colunas;
      final percentual = progresso == null
          ? 'Não informado'
          : progresso.toStringAsFixed(0) + '%';
      return Wrap(
        spacing: 12, runSpacing: 12,
        children: [
          SizedBox(width: larguraCard, child: _indicador(
            label: 'PROGRESSO', value: percentual,
            icon: Icons.insights_outlined, valorProgresso: progresso,
          )),
          SizedBox(width: larguraCard, child: _indicador(
            label: 'SITUAÇÃO', value: _status(status),
            icon: Icons.bolt_outlined,
          )),
          SizedBox(width: larguraCard, child: _indicador(
            label: 'INÍCIO', value: _data(demanda['data_inicio']),
            icon: Icons.play_circle_outline,
          )),
          SizedBox(width: larguraCard, child: _indicador(
            label: 'PREVISÃO', value: _data(demanda['data_previsao']),
            icon: Icons.calendar_today_outlined,
          )),
        ],
      );
    });
  }

  Widget _fluxo(String status) {
    final atual = _posicao(status);
    const rotulos = ['Planejamento', 'Execução', 'Homologação', 'Concluído'];
    const icones = [
      Icons.assignment_outlined, Icons.build_outlined,
      Icons.fact_check_outlined, Icons.check_circle_outline,
    ];
    return _surface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tituloSecao('Jornada da demanda',
          subtitulo: 'Acompanhe em qual fase o atendimento se encontra.'),
        const SizedBox(height: 22),
        LayoutBuilder(builder: (context, c) {
          final compacto = c.maxWidth < 660;
          if (compacto) {
            return Wrap(spacing: 9, runSpacing: 10, children: [
              for (var i = 0; i < rotulos.length; i++)
                _fase(rotulos[i], icones[i], i, atual),
            ]);
          }
          return Row(children: [
            for (var i = 0; i < rotulos.length; i++) ...[
              Expanded(child: _fase(rotulos[i], icones[i], i, atual)),
              if (i < rotulos.length - 1)
                Container(width: 18, height: 2, color: _borda),
            ],
          ]);
        }),
      ]),
    );
  }

  Widget _fase(String label, IconData icone, int indice, int atual) {
    final concluida = atual >= 0 && indice < atual;
    final ativa = indice == atual;
    final cor = ativa ? _azul : concluida ? _verde : _muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
      decoration: BoxDecoration(
        color: ativa ? const Color(0xFF203652) : const Color(0xFF182334),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ativa ? _azul : _borda),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(concluida ? Icons.check_circle : icone, color: cor, size: 17),
        const SizedBox(width: 7),
        Flexible(child: Text(label,
          style: TextStyle(color: cor, fontSize: 12,
            fontWeight: ativa ? FontWeight.w700 : FontWeight.w500))),
      ]),
    );
  }

  Widget _seletorAbas() {
    const abas = ['Resumo', 'Etapas', 'Evidências', 'Histórico'];
    const icones = [
      Icons.dashboard_outlined, Icons.checklist_outlined,
      Icons.attach_file, Icons.history,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (var i = 0; i < abas.length; i++) ...[
          ChoiceChip(
            tooltip: 'Ver ' + abas[i].toLowerCase(),
            showCheckmark: false,
            selected: _aba == i,
            onSelected: (_) => setState(() => _aba = i),
            backgroundColor: _painel,
            selectedColor: const Color(0xFF28456A),
            side: BorderSide(color: _aba == i ? _azul : _borda),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11)),
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icones[i], size: 17,
                color: _aba == i ? _azul : _muted),
              const SizedBox(width: 7),
              Text(abas[i], style: TextStyle(
                color: _aba == i ? _texto : _muted,
                fontWeight: FontWeight.w600,
              )),
            ]),
          ),
          if (i < abas.length - 1) const SizedBox(width: 8),
        ],
      ]),
    );
  }

  Widget _infoLinha(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
        const SizedBox(height: 5),
        Text(valor, style: const TextStyle(color: _texto, height: 1.4)),
      ]),
    );
  }

  Widget _resumo(Map<String, dynamic> demanda, String status) {
    final responsavel = _campo(demanda['responsavel_id'], vazio: '');
    final sobre = _surface(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tituloSecao('Sobre a demanda',
          subtitulo: 'Descrição e objetivo do atendimento.'),
        const SizedBox(height: 19),
        Text(_campo(demanda['descricao'],
            vazio: 'Esta demanda ainda não possui uma descrição.'),
          style: const TextStyle(color: _texto, fontSize: 15, height: 1.65)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF21334B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline, color: _azul, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(
              _posicao(status) == 2
                  ? 'A entrega está em homologação. Confira as evidências antes de registrar sua avaliação.'
                  : _posicao(status) == 3
                      ? 'A demanda está concluída. Consulte o histórico para revisar os registros.'
                      : 'As informações desta tela são atualizadas com os dados registrados pela equipe.',
              style: const TextStyle(color: _texto, height: 1.5),
            )),
          ]),
        ),
      ],
    ));
    final detalhes = _surface(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tituloSecao('Informações gerais'),
        _infoLinha('Código', _campo(demanda['codigo_identificador'])),
        _infoLinha('Responsável', responsavel.isEmpty
            ? 'Aguardando atribuição' : 'Equipe técnica atribuída'),
        _infoLinha('Criada em', _dataHora(demanda['created_at'])),
        _infoLinha('Última atualização', _dataHora(demanda['updated_at'])),
        _infoLinha('Conclusão', _dataHora(demanda['data_conclusao'])),
      ],
    ));
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 790) {
        return Column(children: [
          sobre, const SizedBox(height: 14), detalhes,
        ]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 5, child: sobre),
        const SizedBox(width: 14),
        Expanded(flex: 3, child: detalhes),
      ]);
    });
  }

  Widget _etapas(List<Map<String, dynamic>> lista) {
    final etapas = [...lista]..sort((a, b) => _ordem(a).compareTo(_ordem(b)));
    return _surface(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tituloSecao('Etapas do atendimento',
          subtitulo: 'Atividades registradas pela equipe técnica.'),
        const SizedBox(height: 20),
        if (etapas.isEmpty)
          const Text('Nenhuma etapa registrada.',
            style: TextStyle(color: _muted)),
        for (var i = 0; i < etapas.length; i++) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: etapas[i]['concluida'] == true
                    ? const Color(0xFF1D4B43) : const Color(0xFF2B3950),
              ),
              child: Icon(etapas[i]['concluida'] == true
                  ? Icons.check : Icons.more_horiz,
                  size: 19, color: etapas[i]['concluida'] == true
                    ? _verde : _muted),
            ),
            const SizedBox(width: 13),
            Expanded(child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 17),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_campo(etapas[i]['descricao'], vazio: 'Etapa sem título'),
                    style: const TextStyle(
                      color: _texto, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(etapas[i]['concluida'] == true
                    ? 'Concluída em ' + _dataHora(etapas[i]['concluida_em'])
                    : 'Aguardando conclusão',
                    style: const TextStyle(color: _muted)),
                ],
              ),
            )),
          ]),
          if (i < etapas.length - 1)
            const Divider(color: _borda, height: 12),
        ],
      ],
    ));
  }

  Widget _historico(List<Map<String, dynamic>> lista) {
    final eventos = [...lista];
    eventos.sort((a, b) {
      final dataA = DateTime.tryParse(_campo(a['created_at'], vazio: ''));
      final dataB = DateTime.tryParse(_campo(b['created_at'], vazio: ''));
      if (dataA == null || dataB == null) return 0;
      return dataB.compareTo(dataA);
    });
    return _surface(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tituloSecao('Linha do tempo',
          subtitulo: 'Registro cronológico dos eventos mais recentes primeiro.'),
        const SizedBox(height: 18),
        if (eventos.isEmpty)
          const Text('Nenhum registro no histórico.',
            style: TextStyle(color: _muted)),
        for (var i = 0; i < eventos.length; i++) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 30, height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF24456D), shape: BoxShape.circle),
                child: const Icon(Icons.history, size: 17, color: _azul),
              ),
              if (i < eventos.length - 1)
                Container(width: 2, height: 27, color: _borda),
            ]),
            const SizedBox(width: 13),
            Expanded(child: Padding(
              padding: const EdgeInsets.only(top: 3, bottom: 23),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_evento(_campo(eventos[i]['acao'], vazio: '')),
                    style: const TextStyle(
                      color: _texto, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text(_dataHora(eventos[i]['created_at']),
                    style: const TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            )),
          ]),
        ],
        const Divider(color: _borda),
        const SizedBox(height: 8),
        const Text(
          'Este histórico é somente leitura. Aprovações e solicitações de correção são realizadas na avaliação da entrega.',
          style: TextStyle(color: _muted, height: 1.5),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final demanda = widget.dados.demanda;
    final status = _campo(demanda['status'], vazio: '');
    final progresso = _progresso(demanda['percentual_progresso']);
    return ColoredBox(
      color: _fundo,
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1220),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          children: [
            _cabecalho(demanda, status),
            const SizedBox(height: 26),
            _indicadores(demanda, status, progresso),
            const SizedBox(height: 14),
            _fluxo(status),
            const SizedBox(height: 22),
            _seletorAbas(),
            const SizedBox(height: 17),
            if (_aba == 0) _resumo(demanda, status),
            if (_aba == 1) _etapas(widget.dados.etapas),
            if (_aba == 2) AnexosHomologacaoCard(
              key: ValueKey(widget.demandaId),
              demandaId: widget.demandaId,
              habilitado: false,
              exibirEnvio: false,
            ),
            if (_aba == 3) _historico(widget.dados.historico),
            const SizedBox(height: 30),
          ],
        ),
      )),
    );
  }
}
