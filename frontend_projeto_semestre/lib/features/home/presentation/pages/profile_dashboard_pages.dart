import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../../../demands/data/services/demand_service.dart';
import 'role_dashboard_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({
    super.key,
    required this.session,
    required this.onLogout,
    this.service,
  });
  final AuthSession session;
  final VoidCallback onLogout;
  final DemandService? service;

  @override
  Widget build(BuildContext context) => RoleDashboardPage(
    session: session,
    role: UserRole.admin,
    onLogout: onLogout,
    service: service,
  );
}

class TecnicoDashboardPage extends StatelessWidget {
  const TecnicoDashboardPage({
    super.key,
    required this.session,
    required this.onLogout,
    this.service,
  });
  final AuthSession session;
  final VoidCallback onLogout;
  final DemandService? service;

  @override
  Widget build(BuildContext context) => RoleDashboardPage(
    session: session,
    role: UserRole.tecnico,
    onLogout: onLogout,
    service: service,
  );
}

class ClienteDashboardPage extends StatelessWidget {
  const ClienteDashboardPage({
    super.key,
    required this.session,
    required this.onLogout,
    this.service,
  });
  final AuthSession session;
  final VoidCallback onLogout;
  final DemandService? service;

  @override
  Widget build(BuildContext context) => RoleDashboardPage(
    session: session,
    role: UserRole.cliente,
    onLogout: onLogout,
    service: service,
  );
}
