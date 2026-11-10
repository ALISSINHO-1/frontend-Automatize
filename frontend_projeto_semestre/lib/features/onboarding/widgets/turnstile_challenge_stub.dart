import 'package:flutter/material.dart';

/// Stub para testes e builds nao-web. Cadastro publico so na versao Web.
class TurnstileChallenge extends StatelessWidget {
  const TurnstileChallenge({
    super.key,
    required this.siteKey,
    required this.onToken,
    this.onError,
  });
  final String siteKey;
  final ValueChanged<String?> onToken;
  final ValueChanged<String>? onError;
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text('Validação antirobô disponível na versão Web.'),
  );
}
