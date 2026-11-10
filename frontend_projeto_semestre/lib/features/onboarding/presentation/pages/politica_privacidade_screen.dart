import 'package:flutter/material.dart';

/// Texto informativo inicial: sujeito a revisão jurídica antes de produção.
class PoliticaPrivacidadeScreen extends StatelessWidget {
  const PoliticaPrivacidadeScreen({super.key});

  static const _secoes = [
    (
      '1. Dados tratados',
      'Utilizamos dados de cadastro, como nome e e-mail, informações de autenticação, perfil e vínculos autorizados. Durante o uso, a plataforma pode registrar demandas, mensagens, anexos e histórico de operações.',
    ),
    (
      '2. Finalidades',
      'Esses dados são usados para identificar usuários, controlar acesso, acompanhar projetos, possibilitar a comunicação, registrar entregas e manter a segurança e a rastreabilidade das operações.',
    ),
    (
      '3. Acesso e compartilhamento',
      'As informações devem ser acessadas apenas por pessoas autorizadas, conforme a função e o vínculo com cada projeto ou organização. Prestadores de infraestrutura e comunicação podem tratar dados necessários à operação, sob as condições aplicáveis.',
    ),
    (
      '4. Segurança',
      'Adotamos controles de autenticação, permissões e registro de operações para reduzir acessos indevidos. Nenhuma medida elimina todos os riscos. Não compartilhe sua senha nem inclua credenciais em mensagens ou anexos.',
    ),
    (
      '5. Armazenamento e conservação',
      'As informações são mantidas pelo período necessário para prestar o serviço, cumprir obrigações aplicáveis e atender solicitações legítimas. As condições específicas de conservação e exclusão devem observar os contratos e a legislação.',
    ),
    (
      '6. Direitos das pessoas',
      'Você pode solicitar informações sobre o tratamento de seus dados e exercer os direitos previstos na Lei Geral de Proteção de Dados (LGPD), conforme aplicáveis, pelos canais de atendimento informados na contratação ou no convite de acesso.',
    ),
    (
      '7. Atualizações e contato',
      'Esta política pode ser atualizada para refletir mudanças na plataforma. Para dúvidas sobre privacidade ou solicitações relativas aos seus dados, entre em contato com a equipe responsável pelo Automatize pelo canal fornecido na contratação.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Política de Privacidade')),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AUTOMATIZE  /  VERSÃO 1.0  ·  10/11/2026',
                      style: tema.textTheme.labelLarge?.copyWith(
                        color: tema.colorScheme.primary,
                      )),
                  const SizedBox(height: 16),
                  Text('Sua privacidade importa', style: tema.textTheme.headlineLarge),
                  const SizedBox(height: 12),
                  Text(
                    'Entenda quais informações são utilizadas no portal e para quê.',
                    style: tema.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  for (final (titulo, descricao) in _secoes) ...[
                    const SizedBox(height: 22),
                    Text(titulo, style: tema.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(descricao, style: tema.textTheme.bodyLarge?.copyWith(height: 1.6)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
