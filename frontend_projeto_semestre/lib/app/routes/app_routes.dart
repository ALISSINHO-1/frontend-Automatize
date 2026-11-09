import 'package:flutter/material.dart';

import '/core/auth/auth_guard.dart';
import '/core/auth/technical_role_guard.dart';
import '/features/demands/presentation/pages/technical_demand_list_page.dart';
import '/features/home/presentation/pages/technical_dashboard_page.dart';
import '/features/home/presentation/widgets/admin_layout.dart';
import '/features/home/presentation/widgets/technical_navigation.dart';
import '/core/auth/cliente_guard.dart';
import '/features/admin/presentation/pages/admin_panel_page.dart';
import '/features/admin/presentation/pages/admin_comercial_screen.dart';
import '/features/admin/presentation/pages/clientes_page.dart';
import '/features/admin/presentation/widgets/admin_guard.dart';
import '/features/chat/chat_page.dart';
import '/features/home/presentation/pages/login_screen.dart';
import '/features/onboarding/presentation/pages/cadastro_screen.dart';
import '/features/onboarding/presentation/pages/esqueci_senha_screen.dart';
import '/features/onboarding/presentation/pages/aguardando_vinculo_screen.dart';
import '/features/onboarding/presentation/pages/ambientes_screen.dart';
import '/features/home/presentation/pages/home_page.dart';
import '/features/home/presentation/pages/demandas_screen.dart';
import '/features/home/presentation/pages/painel_screen.dart';
import '/features/demands/presentation/pages/cliente_demanda_detalhes_page.dart';
import '/features/demands/presentation/pages/cliente_ocorrencias_page.dart';
import '/features/demands/presentation/pages/demand_homologation_page.dart';
import '/features/demands/presentation/pages/demand_details_page.dart';
import '/features/demands/presentation/pages/demand_list_page.dart';
import '/features/demands/data/models/pedido_model.dart';

abstract final class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String cadastro = '/cadastro';
  static const String cadastroPendente = '/cadastro/pendente';
  static const String verificarEmail = '/verificar-email';
  static const String redefinirSenha = '/redefinir-senha';
  static const String esqueciSenha = '/esqueci-senha';
  static const String reenviarConfirmacao = '/reenviar-email';
  static const String ambientes = '/ambientes';
  static const String home = '/home';
  static const String painel = '/painel';
  static const String demandas = '/demandas';
  static const String demandDetails = '/demand-details';
  static const String demandList = '/demand-list';
  static const String admin = '/admin';
  static const String comercial = '/admin/comercial';
  static const String clientes = '/clientes';
  static const String chat = '/chat';
  static const String tecnico = TechnicalRoutes.home;
  static const String clienteDetalhes = '/cliente/demandas/detalhes';
  static const String clienteHomologacao = '/cliente/demandas/homologacao';
  static const String clienteOcorrencias = '/cliente/demandas/ocorrencias';

  static final Map<String, WidgetBuilder> routes = {
    // Rotas públicas: apresentação e login.
    landing: (_) => const HomePage(),
    home: (_) => const HomePage(),
    login: (_) => const LoginScreen(),
    cadastro: (_) => const CadastroScreen(),
    esqueciSenha: (_) => const EsqueciSenhaScreen(),
    reenviarConfirmacao: (_) => const EsqueciSenhaScreen(reenviarConfirmacao: true),
    // Tela sem informacoes privadas: um cadastro PENDENTE nao passa no AuthGuard.
    cadastroPendente: (context) {
      final data = ModalRoute.of(context)?.settings.arguments;
      return AguardandoVinculoScreen(
        contexto: data is Map<String, dynamic> ? data : const {},
      );
    },
    ambientes: (context) {
      final data = ModalRoute.of(context)?.settings.arguments;
      // A selecao nao concede acesso. Cada portal valida a permissao na API.
      return AmbientesScreen(
        contexto: data is Map<String, dynamic> ? data : const {},
      );
    },

    // Rotas próprias evitam que a navegação lateral volte à apresentação.
    painel: (_) => const AuthGuard(child: PainelScreen()),
    demandas: (_) => const AuthGuard(child: DemandasScreen()),

    // Rota protegida: exige sessão e perfil ADMIN (GET /auth/me).
    admin: (_) => const AuthGuard(child: AdminGuard(child: AdminPanelPage())),
    comercial: (_) => const AuthGuard(child: AdminGuard(child: AdminComercialScreen())),

    clientes: (_) => const AuthGuard(child: ClientesPage()),

    chat: (_) => const AuthGuard(child: ChatPage()),
    TechnicalRoutes.home: (_) => const TechnicalRoleGuard(
      child: AdminLayout(child: TechnicalDashboardPage()),
    ),
    TechnicalRoutes.demandList: (_) => const TechnicalRoleGuard(
      child: AdminLayout(child: TechnicalDemandListPage()),
    ),
    TechnicalRoutes.demandHistory: (_) => const TechnicalRoleGuard(
      child: Scaffold(body: Center(child: Text('Histórico técnico em implantação.'))),
    ),
    TechnicalRoutes.demandAttachments: (_) => const TechnicalRoleGuard(
      child: Scaffold(body: Center(child: Text('Central de anexos técnicos em implantação.'))),
    ),

    // Portal do cliente. O backend ainda valida o escopo dos registros.
    clienteDetalhes: (context) {
      final id = ModalRoute.of(context)?.settings.arguments;
      return AuthGuard(
        child: ClienteGuard(
          child: id is String && id.trim().isNotEmpty
              ? ClienteDemandaDetalhesPage(demandaId: id)
              : const Scaffold(body: Center(child: Text('Demanda não selecionada.'))),
        ),
      );
    },
    clienteHomologacao: (context) {
      final pedido = ModalRoute.of(context)?.settings.arguments;
      return AuthGuard(
        child: ClienteGuard(
          child: pedido is PedidoModel
              ? DemandHomologationPage(pedido: pedido)
              : const Scaffold(body: Center(child: Text('Demanda não selecionada.'))),
        ),
      );
    },
    clienteOcorrencias: (context) {
      final id = ModalRoute.of(context)?.settings.arguments;
      return AuthGuard(
        child: ClienteGuard(
          child: id is String && id.trim().isNotEmpty
              ? ClienteOcorrenciasPage(demandaId: id)
              : const Scaffold(body: Center(child: Text('Demanda não selecionada.'))),
        ),
      );
    },


    // Rota protegida: lista de demandas.
    demandList: (_) => const AuthGuard(child: DemandListPage()),

    // Rota protegida: detalhes da demanda.
    demandDetails: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments;

      if (arguments is PedidoModel) {
        return AuthGuard(
          child: DemandDetailsPage(demandId: arguments.id, pedido: arguments),
        );
      }

      if (arguments is String) {
        return AuthGuard(child: DemandDetailsPage(demandId: arguments));
      }

      return const AuthGuard(
        child: Scaffold(
          body: Center(child: Text('Nenhuma demanda foi selecionada.')),
        ),
      );
    },
  };
}
