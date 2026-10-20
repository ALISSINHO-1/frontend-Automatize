import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/info_card.dart';
import '../../../../app/routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projeto Semestral')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final horizontalPadding = isWide ? 48.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                32,
                horizontalPadding,
                48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroSection(isWide: isWide),
                      const SizedBox(height: 32),

                      // Botão de Navegação
                      Center(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.demandList);
                          },
                          icon: const Icon(Icons.list_alt),
                          label: const Text('Ver Lista de Demandas'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      Text(
                        'Estrutura inicial',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      _StructureGrid(isWide: isWide),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final introduction = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frontend Web preparado para evoluir',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Base em Flutter Web organizada para receber as regras do projeto, '
          'as telas e a integração com o backend FastAPI sem misturar '
          'responsabilidades desde o primeiro commit.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );

    final environmentCard = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ambiente', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SelectableText(
            AppConfig.environment,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Text('API FastAPI', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SelectableText(
            AppConfig.apiBaseUrl,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 3, child: introduction),
          const SizedBox(width: 32),
          Expanded(flex: 2, child: environmentCard),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [introduction, const SizedBox(height: 24), environmentCard],
    );
  }
}

class _StructureGrid extends StatelessWidget {
  const _StructureGrid({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    const cards = [
      InfoCard(
        icon: Icons.language,
        title: 'Somente Web',
        description:
            'Projeto enxuto para navegador, sem estrutura de Android, iOS, desktop ou outras plataformas.',
      ),
      InfoCard(
        icon: Icons.route_outlined,
        title: 'Rotas centralizadas',
        description:
            'As rotas ficam em uma camada própria para evitar navegação espalhada pelas telas.',
      ),
      InfoCard(
        icon: Icons.api_outlined,
        title: 'API configurável',
        description:
            'A URL do FastAPI pode ser alterada por --dart-define sem editar o código-fonte.',
      ),
      InfoCard(
        icon: Icons.account_tree_outlined,
        title: 'Estrutura por responsabilidade',
        description:
            'App, core, features e shared já estão separados para o sistema crescer sem virar um arquivo main.dart monstruoso.',
      ),
    ];

    if (isWide) {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cards,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          cards[index],
          if (index != cards.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}
