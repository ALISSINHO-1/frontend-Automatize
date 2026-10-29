import 'package:flutter/material.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../../app/routes/app_routes.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
Widget build(BuildContext context) {
  final rotaAtual = ModalRoute.of(context)?.settings.name;

  final emDemandas = rotaAtual == AppRoutes.demandList ||
      rotaAtual == AppRoutes.demandDetails;

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

          _menuItem(
          context,
          Icons.dashboard_rounded,
            'Visão geral',
            selected: !emDemandas,
          ),
          _menuItem(
            context,
            Icons.assignment_outlined,
            'Demandas',
            selected: emDemandas,
          ),
          _menuItem(
            context,
            Icons.history_rounded,
            'Histórico',
          ),
          _menuItem(
            context,
            Icons.folder_outlined,
            'Anexos',
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
  }

      Widget _menuItem(
      BuildContext context,
      IconData icon,
      String title, {
      bool selected = false,
    }) {
    return SidebarMenuItem(
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 220),
  curve: Curves.easeInOutCubic,
  margin: const EdgeInsets.only(bottom: 10),
  decoration: BoxDecoration(
    color: selected
        ? RedesignColors.purple.withValues(alpha: 0.16)
        : Colors.transparent,
    borderRadius: BorderRadius.circular(12),
  ),
      child: ListTile(
      onTap: () {
  if (title == 'Visão geral') {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  } else if (title == 'Demandas') {
    Navigator.pushNamed(
      context,
      AppRoutes.demandList,
    );
  }
},
      dense: true,
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