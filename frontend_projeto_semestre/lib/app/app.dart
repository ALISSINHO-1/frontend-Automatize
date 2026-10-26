import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/demands/data/models/pedido_model.dart';
import '../features/demands/data/services/demand_service.dart';
import '../features/demands/presentation/pages/demand_details_page.dart';
import '../features/demands/presentation/pages/demand_list_page.dart';
import '../features/home/data/auth_service.dart';
import '../features/home/presentation/pages/login_screen.dart';
import '../features/home/presentation/pages/profile_dashboard_pages.dart';
import 'routes/app_routes.dart';

class FaculdadeApp extends StatefulWidget {
  const FaculdadeApp({super.key, this.authService, this.demandServiceFactory});

  final AuthService? authService;
  final DemandService Function(String accessToken, VoidCallback onUnauthorized)?
  demandServiceFactory;

  @override
  State<FaculdadeApp> createState() => _FaculdadeAppState();
}

class _FaculdadeAppState extends State<FaculdadeApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AuthService _authService;
  late final bool _ownsAuthService;

  AuthSession? get _session => _authService.session;

  @override
  void initState() {
    super.initState();
    _ownsAuthService = widget.authService == null;
    _authService = widget.authService ?? AuthService();
  }

  Future<void> _login(String email, String senha) async {
    final session = await _authService.login(email, senha);
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.dashboardFor(session.user.role),
      (_) => false,
    );
  }

  void _logout() {
    if (_authService.session == null) return;
    _authService.logout();
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.home,
      (_) => false,
    );
  }

  DemandService? _testServiceFor(AuthSession session) =>
      widget.demandServiceFactory?.call(session.accessToken, _logout);

  Widget _dashboard(AuthSession session) {
    final service = _testServiceFor(session);
    return switch (session.user.role) {
      UserRole.admin => AdminDashboardPage(
        session: session,
        onLogout: _logout,
        service: service,
      ),
      UserRole.tecnico => TecnicoDashboardPage(
        session: session,
        onLogout: _logout,
        service: service,
      ),
      UserRole.cliente => ClienteDashboardPage(
        session: session,
        onLogout: _logout,
        service: service,
      ),
    };
  }

  Widget _loginScreen() => LoginScreen(onLogin: _login);

  Widget _roleRoute(UserRole requiredRole) {
    final session = _session;
    if (session == null) return _loginScreen();
    if (session.user.role != requiredRole) {
      return _UnauthorizedPage(
        role: session.user.role,
        onReturn: () => _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.dashboardFor(session.user.role),
          (_) => false,
        ),
        onLogout: _logout,
      );
    }
    return _dashboard(session);
  }

  Route<void> _onGenerateRoute(RouteSettings settings) {
    final session = _session;
    final Widget page = switch (settings.name) {
      AppRoutes.home => session == null ? _loginScreen() : _dashboard(session),
      AppRoutes.admin => _roleRoute(UserRole.admin),
      AppRoutes.tecnico => _roleRoute(UserRole.tecnico),
      AppRoutes.cliente => _roleRoute(UserRole.cliente),
      AppRoutes.demandList =>
        session == null
            ? _loginScreen()
            : DemandListPage(
                session: session,
                onLogout: _logout,
                service: _testServiceFor(session),
              ),
      AppRoutes.demandDetails => _buildDetailsRoute(
        settings.arguments,
        session,
      ),
      _ => const _NotFoundPage(),
    };
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }

  Widget _buildDetailsRoute(Object? arguments, AuthSession? session) {
    if (session == null) return _loginScreen();
    if (arguments is PedidoModel) {
      return DemandDetailsPage(
        demandId: arguments.id,
        pedido: arguments,
        session: session,
        onLogout: _logout,
        service: _testServiceFor(session),
      );
    }
    if (arguments is String && arguments.isNotEmpty) {
      return DemandDetailsPage(
        demandId: arguments,
        session: session,
        onLogout: _logout,
        service: _testServiceFor(session),
      );
    }
    return const _NotFoundPage(message: 'Nenhuma demanda foi selecionada.');
  }

  @override
  void dispose() {
    if (_ownsAuthService) _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigatorKey,
    title: 'Automatize',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    onGenerateRoute: _onGenerateRoute,
  );
}

class _UnauthorizedPage extends StatelessWidget {
  const _UnauthorizedPage({
    required this.role,
    required this.onReturn,
    required this.onLogout,
  });

  final UserRole role;
  final VoidCallback onReturn;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Acesso não autorizado')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            Text('Seu perfil ${role.apiValue} não pode abrir esta página.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onReturn,
              child: const Text('Voltar ao meu painel'),
            ),
            TextButton(onPressed: onLogout, child: const Text('Sair')),
          ],
        ),
      ),
    ),
  );
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage({this.message = 'Página não encontrada.'});
  final String message;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(message)));
}
