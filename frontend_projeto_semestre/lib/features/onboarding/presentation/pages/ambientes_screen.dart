import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage_service.dart';

/// O servidor determina os ambientes; a interface nao concede permissoes.
class AmbientesScreen extends StatelessWidget {
  const AmbientesScreen({super.key, required this.contexto});

  final Map<String, dynamic> contexto;

  @override
  Widget build(BuildContext context) {
    final data = contexto['ambientes'];
    final ambientes = data is List ? data.whereType<Map<String, dynamic>>().toList() : <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: const Color(0xFF07172A),
      appBar: AppBar(
        title: const Text('Escolha seu ambiente'),
        backgroundColor: const Color(0xFF07172A),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await LocalStorageService.removeToken();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login, (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Seus espaços de trabalho',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Cada empresa e serviço tem permissões próprias. '
                  'Você só pode acessar vínculos autorizados pela API.',
                  style: TextStyle(color: Color(0xFF9DB1C8))),
              const SizedBox(height: 24),
              if (ambientes.isEmpty)
                const Card(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Nenhum ambiente contratado está disponível.'),
                )),
              for (final a in ambientes)
                Card(
                  color: const Color(0xFF102743),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: Icon(a['tipo'] == 'DEV'
                        ? Icons.code_rounded : Icons.business_rounded,
                        color: const Color(0xFF21B7FF), size: 32),
                    title: Text(a['nome']?.toString() ?? 'Ambiente',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      a['tipo'] == 'DEV' ? 'Projetos de desenvolvimento'
                          : 'Empresa • Perfil: ${a['papel'] ?? 'MEMBRO'}',
                      style: const TextStyle(color: Color(0xFF9DB1C8)),
                    ),
                    trailing: a['tipo'] == 'DEV'
                        ? const Icon(Icons.chevron_right, color: Colors.white)
                        : const Text('Em preparação',
                            style: TextStyle(color: Color(0xFFFFC857))),
                    onTap: a['tipo'] == 'DEV'
                        ? () => Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.painel, (route) => false)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
