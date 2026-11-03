
import 'package:flutter/material.dart';

import '../../../../core/theme/redesign_colors.dart';

import 'technical_navigation.dart';
import 'admin_search_controller.dart';
import 'admin_sidebar.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;

  const AdminLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final larguraTela = MediaQuery.sizeOf(context).width;
    final isDesktop = larguraTela >= 900;

    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => Material(
            color: RedesignColors.background,
            child: Row(
              children: [
                if (isDesktop) const AdminSidebar(),
                Expanded(
                  child: Column(
                    children: [
                      const _AdminTopBar(),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: adminNavigationController,
      builder: (context, _) {
        final rota = adminNavigationController.currentRoute;
        final mostrarBusca = rota == TechnicalRoutes.demandList;

        return Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: const BoxDecoration(
            color: RedesignColors.background,
            border: Border(
              bottom: BorderSide(
                color: RedesignColors.border,
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: mostrarBusca
                      ? const _DemandSearchField()
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 16),
              const Tooltip(
                message: 'Notificações indisponíveis na demonstração',
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: RedesignColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 24),
              const CircleAvatar(
                radius: 17,
                backgroundColor: RedesignColors.purple,
                child: Text(
                  'LS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (MediaQuery.sizeOf(context).width >= 700) ...[
                const Text(
                  'Lucas Silva',
                  style: TextStyle(
                    color: RedesignColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: RedesignColors.textSecondary,
                  size: 18,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DemandSearchField extends StatefulWidget {
  const _DemandSearchField();

  @override
  State<_DemandSearchField> createState() =>
      _DemandSearchFieldState();
}

class _DemandSearchFieldState extends State<_DemandSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: adminSearchController.query,
    );

    _controller.addListener(_atualizarBusca);
  }

  void _atualizarBusca() {
    adminSearchController.atualizarBusca(_controller.text);
  }

  void _limparBusca() {
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.removeListener(_atualizarBusca);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: RedesignColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: RedesignColors.border,
            width: 0.7,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(
              Icons.search_rounded,
              color: RedesignColors.textSecondary,
              size: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(
                  color: RedesignColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  hintText: 'Buscar demandas...',
                  hintStyle: TextStyle(
                    color: RedesignColors.textSecondary,
                    fontSize: 12,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) {
                  return const SizedBox(width: 12);
                }

                return IconButton(
                  onPressed: _limparBusca,
                  tooltip: 'Limpar pesquisa',
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: RedesignColors.textSecondary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
