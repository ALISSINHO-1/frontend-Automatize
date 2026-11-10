import 'package:flutter/material.dart';

// Ao alterar o texto, mantenha a versão anterior no histórico do repositório
// e atualize esta versão em conjunto com a API de cadastro.
const termosUsoVersao = '1.0';

class TermosUsoScreen extends StatelessWidget {
  const TermosUsoScreen({super.key});

  static const _secoes = [
    (
      '1. Sobre o Automatize',
      'O Automatize é um portal para acompanhar demandas de software. Conforme '
          'seu perfil e vínculo, você pode consultar o andamento de projetos, '
          'trocar mensagens, enviar anexos e participar da homologação de entregas.',
    ),
    (
      '2. Conta e acesso',
      'Informe dados corretos no cadastro, confirme seu e-mail e mantenha sua '
          'senha em sigilo. Sua conta é pessoal. A criação da conta inicia a '
          'solicitação de acesso. As áreas de trabalho ficam disponíveis conforme '
          'o vínculo e as permissões autorizadas para você.',
    ),
    (
      '3. Uso da plataforma',
      'Use o portal para atividades relacionadas aos projetos aos quais você tem '
          'acesso. Respeite a confidencialidade e os direitos de outras pessoas. '
          'Envie somente materiais que você tenha autorização para compartilhar '
          'e evite incluir senhas ou dados pessoais desnecessários. É proibido '
          'tentar acessar contas ou projetos de terceiros, enviar arquivos maliciosos '
          'ou interferir no funcionamento da plataforma.',
    ),
    (
      '4. Demandas, entregas e contratação',
      'O aceite destes termos se refere ao uso da plataforma. A aprovação de uma '
          'entrega ocorre separadamente na homologação da demanda. Condições '
          'comerciais, prazos de projeto e direitos sobre as entregas seguem o '
          'contrato aplicável, quando houver.',
    ),
    (
      '5. Dados e privacidade',
      'O cadastro usa nome e e-mail para identificar sua conta e enviar a '
          'confirmação. O Automatize registra a versão dos termos e o momento do '
          'aceite. Mensagens e anexos integram os projetos em que você os '
          'compartilha. Você pode solicitar informações e exercer seus direitos '
          'sobre dados pessoais conforme a legislação aplicável.',
    ),
    (
      '6. Disponibilidade e segurança',
      'O portal pode passar por manutenções e atualizações. O acesso pode ser '
          'restringido quando necessário para proteger contas ou projetos ou '
          'conter uso indevido. Permanecem assegurados os direitos e garantias '
          'previstos na legislação aplicável.',
    ),
    (
      '7. Atualizações e contato',
      'As atualizações serão identificadas pela versão publicada nesta página. '
          'Para dúvidas sobre sua conta, comunicar um incidente ou solicitar '
          'atendimento, procure a equipe responsável pelo Automatize pelo '
          'canal informado no convite ou na contratação.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Termos de Uso')),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AUTOMATIZE  /  VERSÃO $termosUsoVersao',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Termos de Uso', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 12),
                  Text(
                    'Leia as condições de acesso e uso do portal Automatize.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  for (final (titulo, texto) in _secoes) ...[
                    const SizedBox(height: 22),
                    Text(titulo, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      texto,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
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
