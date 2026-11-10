import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../shared/widgets/main_layout.dart';
import 'demanda_store.dart';

class PainelScreen extends StatefulWidget {
  const PainelScreen({super.key});
  @override
  State<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends State<PainelScreen> {
  final DemandaStore _store = DemandaStore.instance;
  static const _corTexto = AutomatizeColors.text;
  static const _corSecundaria = AutomatizeColors.muted;
  static const _corBorda = AutomatizeColors.border;
  @override
  void initState() {
    super.initState();
    _store.addListener(_atualizarPainel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _store.carregarDemandas();
    });
  }

  void _atualizarPainel() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_atualizarPainel);
    super.dispose();
  }

  // Traduz os estados do backend apenas para apresentação.
  String _rotuloEstado(String estado) {
    switch (estado.trim().toUpperCase()) {
      case 'PLANEAMENTO':
      case 'PLANEJAMENTO':
        return 'Planejamento';
      case 'EXECUCAO':
      case 'EXECUÇÃO':
        return 'Execução';
      case 'HOMOLOGACAO':
      case 'HOMOLOGAÇÃO':
        return 'Homologação';
      case 'CONCLUIDO':
      case 'CONCLUÍDO':
        return 'Concluído';
      default:
        return estado.trim().isEmpty ? 'Não informado' : estado;
    }
  }

  Color _corStatus(String estado) {
    switch (_rotuloEstado(estado)) {
      case 'Planejamento':
        return AutomatizeColors.purple;
      case 'Execução':
        return AutomatizeColors.primary;
      case 'Homologação':
        return AutomatizeColors.warning;
      case 'Concluído':
        return AutomatizeColors.success;
      default:
        return AutomatizeColors.muted;
    }
  }

  String _textoProgresso(DemandaItem demanda) {
    if (!demanda.progressoInformado) return 'Não informado';
    return '${demanda.progresso.toStringAsFixed(2).replaceAll('.', ',')}%';
  }

  Widget _barraProgresso(DemandaItem demanda) {
    if (!demanda.progressoInformado) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: _corBorda,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }
    return LinearProgressIndicator(
      value: (demanda.progresso / 100).clamp(0.0, 1.0),
      minHeight: 6,
      backgroundColor: _corBorda,
      valueColor: AlwaysStoppedAnimation<Color>(_corStatus(demanda.estado)),
      borderRadius: BorderRadius.circular(8),
    );
  }

  void _navegarParaDemandas() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.demandas);
  }

  Future<void> _sair() async {
    await LocalStorageService.removeToken();
    _store.limpar();
    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) _navegarParaDemandas();
      },
      onLogout: _sair,
      child: Scaffold(
        backgroundColor: AutomatizeColors.background,
        body: SafeArea(
          child: _store.carregando
              ? const Center(child: CircularProgressIndicator())
              : _store.erro != null
              ? _estadoErro(_store.erro!)
              : _conteudoPainel(_store.demandas),
        ),
      ),
    );
  }

  Widget _estadoErro(String mensagem) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AutomatizeColors.danger),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _store.carregarDemandas,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudoPainel(List<DemandaItem> demandas) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Painel',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _corTexto,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Acompanhe o resumo das suas demandas.',
            style: TextStyle(color: _corSecundaria, fontSize: 14),
          ),
          const SizedBox(height: 28),
          _tituloSecao('Visão geral'),
          const SizedBox(height: 16),
          _indicadores(demandas),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _tituloSecao('Demandas recentes'),
              TextButton.icon(
                onPressed: _navegarParaDemandas,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _listaRecentes(demandas),
          const SizedBox(height: 16),
          const Text(
            'As informações exibidas são consultadas na API.',
            style: TextStyle(color: _corSecundaria, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _tituloSecao(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: _corTexto,
      ),
    );
  }

  Widget _indicadores(List<DemandaItem> demandas) {
    int contar(String estado) {
      return demandas.where((d) => _rotuloEstado(d.estado) == estado).length;
    }

    final cards = <Widget>[
      _IndicadorCard(
        titulo: 'Total de demandas',
        valor: '${demandas.length}',
        descricao: 'Demandas cadastradas',
        icone: Icons.assignment_outlined,
        cor: AutomatizeColors.primary,
      ),
      _IndicadorCard(
        titulo: 'Planejamento',
        valor: '${contar('Planejamento')}',
        descricao: 'Em planejamento',
        icone: Icons.calendar_month_outlined,
        cor: AutomatizeColors.purple,
      ),
      _IndicadorCard(
        titulo: 'Execução',
        valor: '${contar('Execução')}',
        descricao: 'Em execução',
        icone: Icons.build_circle_outlined,
        cor: AutomatizeColors.primary,
      ),
      _IndicadorCard(
        titulo: 'Homologação',
        valor: '${contar('Homologação')}',
        descricao: 'Em homologação',
        icone: Icons.fact_check_outlined,
        cor: AutomatizeColors.cyan,
      ),
      _IndicadorCard(
        titulo: 'Concluídas',
        valor: '${contar('Concluído')}',
        descricao: 'Finalizadas',
        icone: Icons.check_circle_outline,
        cor: AutomatizeColors.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        const larguraMinima = 205.0;
        final colunas = ((constraints.maxWidth + gap) / (larguraMinima + gap))
            .floor()
            .clamp(1, 5)
            .toInt();
        final largura = (constraints.maxWidth - (colunas - 1) * gap) / colunas;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: largura, child: card),
          ],
        );
      },
    );
  }

  Widget _listaRecentes(List<DemandaItem> demandas) {
    final ordenadas = [...demandas]
      ..sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
    final recentes = ordenadas.take(5).toList();
    return Card(
      elevation: 0,
      color: AutomatizeColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _corBorda),
      ),
      child: recentes.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 42,
                      color: _corSecundaria,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Nenhuma demanda cadastrada.',
                      style: TextStyle(color: _corSecundaria),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentes.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: _corBorda),
              itemBuilder: (context, index) => _itemRecente(recentes[index]),
            ),
    );
  }

  Widget _itemRecente(DemandaItem demanda) {
    final cor = _corStatus(demanda.estado);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.assignment_outlined, color: cor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  demanda.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _corTexto,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  demanda.codigo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _corSecundaria),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _rotuloEstado(demanda.estado),
                        style: TextStyle(
                          color: cor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Progresso: ${_textoProgresso(demanda)}',
                      style: const TextStyle(
                        color: _corSecundaria,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _barraProgresso(demanda),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicadorCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String descricao;
  final IconData icone;
  final Color cor;
  const _IndicadorCard({
    required this.titulo,
    required this.valor,
    required this.descricao,
    required this.icone,
    required this.cor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 138),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AutomatizeColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: AutomatizeColors.muted,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(icone, color: cor, size: 23),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            valor,
            style: const TextStyle(
              color: AutomatizeColors.text,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            descricao,
            style: const TextStyle(color: AutomatizeColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
