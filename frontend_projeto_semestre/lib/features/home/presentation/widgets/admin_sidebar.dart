
import 'package:flutter/material.dart';

import '../../../../core/theme/redesign_colors.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/app.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  static const double _itemHeight = 48;
  static const double _itemSpacing = 10;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: adminNavigationController,
      builder: (context, child) {
        final rotaAtual = adminNavigationController.currentRoute;

        final emDemandas = rotaAtual == AppRoutes.demandList ||
            rotaAtual == AppRoutes.demandDetails;

        final selectedIndex = emDemandas ? 1 : 0;

        return Container(
          width: 250,
          color: RedesignColors.sidebar,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: RedesignColors.purple,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'AUTOMATIZE',
                    style: TextStyle(
                      color: RedesignColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Menu com indicador roxo deslizante.
              SizedBox(
                height: (_itemHeight + _itemSpacing) * 4,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      top: selectedIndex * (_itemHeight + _itemSpacing),
                      left: 0,
                      right: 0,
                      height: _itemHeight,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: RedesignColors.purple
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    Column(
                      children: [
                        _menuItem(
                          Icons.dashboard_rounded,
                          'Visão geral',
                          selected: !emDemandas,
                        ),
                        _menuItem(
                          Icons.assignment_outlined,
                          'Demandas',
                          selected: emDemandas,
                        ),
                        _menuItem(
                          Icons.history_rounded,
                          'Histórico',
                        ),
                        _menuItem(
                          Icons.folder_outlined,
                          'Anexos',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              const Divider(color: RedesignColors.border),
              const SizedBox(height: 16),

              const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: RedesignColors.purple,
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administrador',
                          style: TextStyle(
                            color: RedesignColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ambiente demonstrativo',
                          style: TextStyle(
                            color: RedesignColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem(
    IconData icon,
    String title, {
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _itemSpacing),
      child: SidebarMenuItem(
        child: SizedBox(
          height: _itemHeight,
          child: ListTile(
            onTap: () {
              final navigator = adminNavigatorKey.currentState;

              if (navigator == null) return;

              if (title == 'Visão geral') {
                if (adminNavigationController.currentRoute ==
                    AppRoutes.home) {
                  return;
                }

                navigator.pushNamedAndRemoveUntil(
                  AppRoutes.home,
                  (route) => false,
                );
              } else if (title == 'Demandas') {
              if (adminNavigationController.currentRoute ==
                  AppRoutes.demandList) {
                return;
              }

              adminNavigationController.setRoute(AppRoutes.demandList);

              navigator.pushNamed(AppRoutes.demandList);
              }
            },
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            leading: Icon(
              icon,
              color: selected
                  ? RedesignColors.purple
                  : RedesignColors.textSecondary,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: selected
                    ? RedesignColors.textPrimary
                    : RedesignColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SidebarMenuItem extends StatefulWidget {
  final Widget child;

  const SidebarMenuItem({
    super.key,
    required this.child,
  });

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isHovered
              ? RedesignColors.purple.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.child,
      ),
    );
  }
}
