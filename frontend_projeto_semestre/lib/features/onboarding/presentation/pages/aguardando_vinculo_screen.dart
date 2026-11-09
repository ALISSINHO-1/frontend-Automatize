import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage_service.dart';

/// Area segura para uma identidade sem servico ou empresa autorizados.
class AguardandoVinculoScreen extends StatelessWidget {
  const AguardandoVinculoScreen({
    super.key,
    this.contexto = const {},
  });

  final Map<String, dynamic> contexto;

  Future<void> _sair(BuildContext context) async {
    await LocalStorageService.removeToken();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login, (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final confirmado = contexto['email_verificado'] == true;
    return Scaffold(
      backgroundColor: const Color(0xFF07172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07172A),
        title: const Text('Minha conta'),
        actions: [
          TextButton.icon(
            onPressed: () => _sair(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Card(
            color: const Color(0xFF102743),
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      size: 62, color: Color(0xFF21B7FF)),
                  const SizedBox(height: 20),
                  Text(confirmado ? 'Aguardando vínculo comercial' : 'Confirme seu e-mail',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Text(
                    confirmado
                        ? 'Seu e-mail está confirmado. A equipe ainda precisa vincular um serviço DEV ou uma empresa à sua conta.'
                        : 'Verifique sua caixa de entrada para confirmar o e-mail. Sem confirmação e contrato, não há acesso às demandas ou empresas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF9DB1C8), height: 1.6)),
                  const SizedBox(height: 26),
                  OutlinedButton.icon(
                    onPressed: () => _sair(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Voltar ao login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
