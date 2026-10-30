import 'package:flutter/material.dart';
import '../../app/routes/app_routes.dart';
import '../../core/storage/local_storage_service.dart';
import '../../features/admin/presentation/widgets/admin_guard.dart';

/// Paleta visual compartilhada pelas telas do Automatize.
class AutomatizeColors {
  static const background = Color(0xFF07172A);
  static const sidebar = Color(0xFF0A1B30);
  static const panel = Color(0xFF102743);
  static const panelLight = Color(0xFF173452);
  static const primary = Color(0xFF168BFF);
  static const cyan = Color(0xFF21B7FF);
  static const text = Color(0xFFF4F7FB);
  static const muted = Color(0xFF9DB1C8);
  static const border = Color(0xFF294866);
  static const success = Color(0xFF2FD3A1);
  static const warning = Color(0xFFFFC857);
  static const purple = Color(0xFFB784FF);
  static const danger = Color(0xFFFF5364);
}

class MainLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final VoidCallback? onLogout;

  const MainLayout({
    super.key,
    required this.child,
    this.selectedIndex = 1,
    this.onDestinationSelected,
    this.onLogout,
  });

  /// Item "Painel administrativo" (só aparece para o perfil ADMIN).
  static const int indiceAdmin = 3;

  // Aliases mantidos para não quebrar as telas existentes.
  static const Color sidebarColor = AutomatizeColors.sidebar;
  static const Color activeColor = AutomatizeColors.primary;

  Future<void> _confirmarSaida(BuildContext context) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AutomatizeColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AutomatizeColors.border),
        ),
        icon: const Icon(
          Icons.logout_rounded,
          color: AutomatizeColors.warning,
          size: 30,
        ),
        title: const Text(
          'Sair da conta?',
          style: TextStyle(
            color: AutomatizeColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Você precisará entrar novamente para acessar suas demandas.',
          style: TextStyle(color: AutomatizeColors.muted, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AutomatizeColors.text,
              side: const BorderSide(color: AutomatizeColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continuar aqui'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AutomatizeColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.logout_rounded, size: 17),
            label: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;

    // Encerra a sessão antes de iniciar a navegação.
    await LocalStorageService.removeToken();
    if (!context.mounted) return;

    if (onLogout != null) {
      onLogout!();
      return;
    }

    // Mantém o logout funcional mesmo sem um callback na tela.
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  void _selecionarDestino(BuildContext context, int index, String label) {
    if (selectedIndex == index) return;
    // A área admin tem rota própria; as telas existentes não precisam tratá-la.
    if (index == indiceAdmin) {
      Navigator.of(context).pushNamed(AppRoutes.admin);
      return;
    }
    if (onDestinationSelected != null) {
      onDestinationSelected!(index);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('A navegação para "$label" ainda não foi conectada.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final sidebarWidth = compact ? 78.0 : 252.0;
        return Row(
          children: [
            Container(
              width: sidebarWidth,
              decoration: const BoxDecoration(
                color: AutomatizeColors.sidebar,
                border: Border(
                  right: BorderSide(color: AutomatizeColors.border, width: 0.7),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 15 : 21,
                        vertical: 25,
                      ),
                      child: compact
                          ? const _BrandIcon()
                          : const Row(
                              children: [
                                _BrandIcon(),
                                SizedBox(width: 11),
                                Expanded(child: _BrandName()),
                              ],
                            ),
                    ),
                    if (!compact)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(22, 4, 18, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ÁREA DO CLIENTE',
                            style: TextStyle(
                              color: Color(0xFF66819D),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ),
                    _navigationItem(
                      context,
                      compact: compact,
                      index: 0,
                      icon: Icons.grid_view_rounded,
                      label: 'Painel',
                    ),
                    _navigationItem(
                      context,
                      compact: compact,
                      index: 1,
                      icon: Icons.assignment_rounded,
                      label: 'Minhas demandas',
                    ),
                    AdminMenuGate(
                      child: _navigationItem(
                        context,
                        compact: compact,
                        index: indiceAdmin,
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Painel administrativo',
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 10 : 15,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 0 : 12,
                          vertical: compact ? 12 : 13,
                        ),
                        decoration: BoxDecoration(
                          color: AutomatizeColors.panel,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AutomatizeColors.border),
                        ),
                        child: compact
                            ? const Center(child: _UserAvatar())
                            : const Row(
                                children: [
                                  _UserAvatar(),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Minha conta',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: AutomatizeColors.text,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Cliente',
                                          style: TextStyle(
                                            color: AutomatizeColors.muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.more_horiz,
                                    color: AutomatizeColors.muted,
                                    size: 19,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _navigationItem(
                      context,
                      compact: compact,
                      index: 2,
                      icon: Icons.logout_rounded,
                      label: 'Sair da conta',
                      isLogout: true,
                    ),
                    const SizedBox(height: 16),
                    if (!compact)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 14),
                        child: Text(
                          'AUTOMATIZE  •  CLIENTE',
                          style: TextStyle(
                            color: Color(0xFF58728E),
                            fontSize: 9,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }

  Widget _navigationItem(
    BuildContext context, {
    required bool compact,
    required int index,
    required IconData icon,
    required String label,
    bool isLogout = false,
  }) {
    final selected = selectedIndex == index && !isLogout;
    final foreground = isLogout
        ? const Color(0xFFFF8994)
        : AutomatizeColors.muted;
    final item = Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 13, vertical: 4),
      child: Material(
        color: selected
            ? AutomatizeColors.primary.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () {
            if (isLogout) {
              _confirmarSaida(context);
            } else {
              _selecionarDestino(context, index, label);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 0 : 13,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected
                    ? AutomatizeColors.primary.withValues(alpha: 0.45)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: selected ? AutomatizeColors.cyan : foreground,
                  size: 20,
                ),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? AutomatizeColors.text : foreground,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AutomatizeColors.cyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return Tooltip(message: compact ? label : '', child: item);
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AutomatizeColors.cyan, AutomatizeColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AutomatizeColors.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

class _BrandName extends StatelessWidget {
  const _BrandName();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AUTOMATIZE',
          style: TextStyle(
            color: AutomatizeColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Gestão de demandas',
          style: TextStyle(
            color: AutomatizeColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF249BFF), Color(0xFF655DFF)],
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            'CL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AutomatizeColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: AutomatizeColors.panel, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
