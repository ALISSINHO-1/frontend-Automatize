import 'package:flutter/material.dart';

import '../../../demands/presentation/pages/demand_list_page.dart';
import '../../data/auth_service.dart';

/// Legacy entry point kept for existing callers; delegates to the authenticated
/// demand list so every role uses the same Bearer-protected API flow.
class DemandasScreen extends StatelessWidget {
  const DemandasScreen({
    super.key,
    required this.session,
    required this.onLogout,
  });

  final AuthSession session;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) =>
      DemandListPage(session: session, onLogout: onLogout);
}
