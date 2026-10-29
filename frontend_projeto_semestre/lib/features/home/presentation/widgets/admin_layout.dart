import 'package:flutter/material.dart';

import 'admin_sidebar.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;

  const AdminLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Row(
          children: [
            if (isDesktop) const AdminSidebar(),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}