import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import 'profile_dashboard_pages.dart';

/// Compatibility entry point retained for the existing administrative home.
/// The role dashboard now reads its data from the authenticated API session.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.session, required this.onLogout});

  final AuthSession session;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) =>
      AdminDashboardPage(session: session, onLogout: onLogout);
}
