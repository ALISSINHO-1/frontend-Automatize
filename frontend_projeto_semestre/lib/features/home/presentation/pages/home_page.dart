import 'package:flutter/material.dart';
import 'demandas_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const fundo = Color(0xFF07172A);
  static const painel = Color(0xFF102743);
  static const azul = Color(0xFF168BFF);
  static const ciano = Color(0xFF21B7FF);
  static const texto = Color(0xFFF4F7FB);
  static const secundario = Color(0xFF9DB1C8);
  static const borda = Color(0xFF294866);
  static const verde = Color(0xFF2FD3A1);
  static const roxo = Color(0xFFB784FF);

  void _abrirDemandas(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DemandasScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF07172A),
              Color(0xFF0A1C31),
              Color(0xFF102943),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final largo = constraints.maxWidth >= 850;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: largo ? 38 : 20,
                  vertical: 26,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 1200,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cabecalho(context, largo),
                        SizedBox(height: largo ? 65 : 40),
                        _secaoPrincipal(context, largo),
                        const SizedBox(height: 55),
                        _tituloFuncionalidades(),
                        const SizedBox(height: 20),
                        _listaFuncionalidades(),
                        const SizedBox(height: 40),
                        _rodape(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // CABEÇALHO

  Widget _cabecalho(BuildContext context, bool largo) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ciano, azul],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AUTOMATIZE',
                style: TextStyle(
                  color: texto,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Gestão de demandas',
                style: TextStyle(
                  color: secundario,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (largo) ...[
          const Icon(
            Icons.verified_user_outlined,
            color: verde,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Text(
            'Portal do cliente',
            style: TextStyle(
              color: secundario,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 20),
        ],
        OutlinedButton.icon(
          onPressed: () => _abrirDemandas(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: texto,
            side: const BorderSide(color: borda),
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(
            Icons.assignment_outlined,
            size: 18,
          ),
          label: Text(
            largo ? 'Minhas demandas' : 'Demandas',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // APRESENTAÇÃO PRINCIPAL

  Widget _secaoPrincipal(BuildContext context, bool largo) {
    final apresentacao = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: azul.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: azul.withValues(alpha: 0.35),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt_rounded,
                color: ciano,
                size: 16,
              ),
              SizedBox(width: 7),
              Text(
                'GESTÃO MAIS SIMPLES',
                style: TextStyle(
                  color: ciano,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Suas demandas,\nsob controle.',
          style: TextStyle(
            color: texto,
            fontSize: largo ? 48 : 36,
            fontWeight: FontWeight.w900,
            height: 1.15,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Acompanhe o andamento das atividades, consulte '
          'informações e visualize cada etapa do seu projeto '
          'em um único lugar.',
          style: TextStyle(
            color: secundario,
            fontSize: 14,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => _abrirDemandas(context),
              style: FilledButton.styleFrom(
                backgroundColor: azul,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: const Text(
                'Ver lista de demandas',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _mostrarInformacoes(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: texto,
                side: const BorderSide(color: borda),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.info_outline_rounded,
                size: 18,
              ),
              label: const Text(
                'Conheça a plataforma',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );

    if (!largo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          apresentacao,
          const SizedBox(height: 32),
          _cartaoEtapas(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 11,
          child: Padding(
            padding: const EdgeInsets.only(right: 35),
            child: apresentacao,
          ),
        ),
        const SizedBox(width: 15),
        const Expanded(
          flex: 9,
          child: _CartaoEtapas(),
        ),
      ],
    );
  }

  Widget _cartaoEtapas() {
    return const _CartaoEtapas();
  }

  // TÍTULO DAS FUNCIONALIDADES

  Widget _tituloFuncionalidades() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tudo o que você precisa, em um só lugar',
          style: TextStyle(
            color: texto,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Recursos para facilitar o acompanhamento do projeto.',
          style: TextStyle(
            color: secundario,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // CARTÕES DE FUNCIONALIDADES

  Widget _listaFuncionalidades() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;
        final larguraCartao = largura >= 1000
            ? (largura - 32) / 3
            : largura >= 650
                ? (largura - 16) / 2
                : largura;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: larguraCartao,
              child: const _CartaoFuncionalidade(
                icone: Icons.track_changes_rounded,
                cor: ciano,
                numero: '01',
                titulo: 'Acompanhamento',
                descricao:
                    'Consulte o estado das demandas e saiba em '
                    'qual etapa o trabalho se encontra.',
              ),
            ),
            SizedBox(
              width: larguraCartao,
              child: const _CartaoFuncionalidade(
                icone: Icons.insights_rounded,
                cor: verde,
                numero: '02',
                titulo: 'Progresso visível',
                descricao:
                    'Visualize o andamento das atividades por '
                    'meio de indicadores claros.',
              ),
            ),
            SizedBox(
              width: larguraCartao,
              child: const _CartaoFuncionalidade(
                icone: Icons.description_outlined,
                cor: roxo,
                numero: '03',
                titulo: 'Informações organizadas',
                descricao:
                    'Encontre códigos, descrições e detalhes '
                    'das demandas em um só lugar.',
              ),
            ),
          ],
        );
      },
    );
  }

  // JANELA DE INFORMAÇÕES

  void _mostrarInformacoes(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: painel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: borda),
          ),
          title: const Text(
            'Conheça o Automatize',
            style: TextStyle(
              color: texto,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'O Automatize é um portal para consultar as demandas '
            'do projeto, visualizar seus estados e acompanhar o '
            'progresso das atividades. As informações exibidas '
            'dependem dos dados disponibilizados pelo sistema.',
            style: TextStyle(
              color: secundario,
              fontSize: 13,
              height: 1.7,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _abrirDemandas(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: azul,
              ),
              child: const Text('Ver demandas'),
            ),
          ],
        );
      },
    );
  }

  // RODAPÉ

  Widget _rodape() {
    return const Padding(
      padding: EdgeInsets.only(top: 22),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: ciano,
            size: 17,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'AUTOMATIZE · Portal de acompanhamento de demandas',
              style: TextStyle(
                color: secundario,
                fontSize: 10,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CARTÃO COM AS ETAPAS

class _CartaoEtapas extends StatelessWidget {
  const _CartaoEtapas();

  static const fundo = HomePage.fundo;
  static const ciano = HomePage.ciano;
  static const azul = HomePage.azul;
  static const texto = HomePage.texto;
  static const secundario = HomePage.secundario;
  static const borda = HomePage.borda;
  static const verde = HomePage.verde;
  static const roxo = HomePage.roxo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF153657),
            Color(0xFF102743),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                color: ciano,
                size: 26,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fluxo de acompanhamento',
                      style: TextStyle(
                        color: texto,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Etapas do projeto',
                      style: TextStyle(
                        color: secundario,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _Etapa(
            numero: '01',
            titulo: 'Planejamento',
            descricao: 'Organização das atividades',
            cor: azul,
            icone: Icons.event_note_rounded,
          ),
          _conector(azul),
          _Etapa(
            numero: '02',
            titulo: 'Desenvolvimento',
            descricao: 'Execução do trabalho',
            cor: ciano,
            icone: Icons.code_rounded,
          ),
          _conector(ciano),
          _Etapa(
            numero: '03',
            titulo: 'Homologação',
            descricao: 'Validação das entregas',
            cor: roxo,
            icone: Icons.fact_check_outlined,
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: fundo.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borda),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  color: verde,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mais visibilidade em cada etapa do projeto.',
                    style: TextStyle(
                      color: secundario,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _conector(Color cor) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 21,
        top: 5,
        bottom: 5,
      ),
      child: Container(
        width: 2,
        height: 19,
        color: cor.withValues(alpha: 0.35),
      ),
    );
  }
}

// ETAPA INDIVIDUAL

class _Etapa extends StatelessWidget {
  const _Etapa({
    required this.numero,
    required this.titulo,
    required this.descricao,
    required this.cor,
    required this.icone,
  });

  final String numero;
  final String titulo;
  final String descricao;
  final Color cor;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cor.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            icone,
            color: cor,
            size: 21,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$numero · $titulo',
                style: const TextStyle(
                  color: HomePage.texto,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                descricao,
                style: const TextStyle(
                  color: HomePage.secundario,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          color: cor,
          size: 13,
        ),
      ],
    );
  }
}

// CARTÕES DE FUNCIONALIDADES

class _CartaoFuncionalidade extends StatelessWidget {
  const _CartaoFuncionalidade({
    required this.icone,
    required this.cor,
    required this.numero,
    required this.titulo,
    required this.descricao,
  });

  final IconData icone;
  final Color cor;
  final String numero;
  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: HomePage.painel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomePage.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icone,
                  color: cor,
                  size: 23,
                ),
              ),
              Text(
                numero,
                style: const TextStyle(
                  color: Color(0xFF58728E),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            titulo,
            style: const TextStyle(
              color: HomePage.texto,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            descricao,
            style: const TextStyle(
              color: HomePage.secundario,
              fontSize: 11,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}