import 'package:flutter/material.dart';

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

  static const Color sidebarColor = Color(0xFF0F172A);
  static const Color activeColor = Color(0xFF1677F2);

  Future<void> _confirmarSaida(BuildContext context) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Deseja realmente sair do Automatize?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmou != true || !context.mounted) {
      return;
    }

    if (onLogout != null) {
      onLogout!();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A navegação para o login ainda precisa ser conectada.',
        ),
      ),
    );
  }

  void _selecionarDestino(
    BuildContext context,
    int index,
    String label,
  ) {
    if (selectedIndex == index) {
      return;
    }

    if (onDestinationSelected != null) {
      onDestinationSelected!(index);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'A navegação para "$label" ainda não foi conectada.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 245,
          color: sidebarColor,
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.change_circle,
                        color: Color(0xFF38BDF8),
                        size: 32,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'AUTOMATIZE', 
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _navigationItem(
                  context,
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  label: 'Painel',
                ),

                _navigationItem(
                  context,
                  index: 1,
                  icon: Icons.assignment_outlined,
                  label: 'Demandas',
                ),

                _navigationItem(
                  context,
                  index: 2,
                  icon: Icons.logout,
                  label: 'Sair',
                  isLogout: true,
                ),

                const Spacer(),

                const Divider(
                  color: Color(0xFF334155),
                  indent: 16,
                  endIndent: 16,
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF2563EB),
                        child: Text(
                          'MC',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Mariana Costa',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                                height: 1.2,
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              'Cliente',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                decoration: TextDecoration.none,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: child,
        ),
      ],
    );
  }

  Widget _navigationItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    bool isLogout = false,
  }) {
    final bool selected =
        selectedIndex == index && !isLogout;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Material(
        color: selected
            ? activeColor
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (isLogout) {
              _confirmarSaida(context);
              return;
            }

            _selecionarDestino(
              context,
              index,
              label,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? Colors.white
                      : const Color(0xFFCBD5E1),
                  size: 21,
                ),

                const SizedBox(width: 12),

                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : const Color(0xFFCBD5E1),
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}