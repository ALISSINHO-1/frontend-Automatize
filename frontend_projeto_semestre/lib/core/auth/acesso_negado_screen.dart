import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';

/// Tela segura para perfis desconhecidos ou sem portal integrado.
class AcessoNegadoScreen extends StatelessWidget {
  const AcessoNegadoScreen({
    super.key,
    required this.titulo,
    required this.mensagem,
  });

  final String titulo;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07172A),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFFFFC857),
                    size: 48,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    mensagem,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF9DB1C8),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    },
                    child: const Text('Voltar ao login'),
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
