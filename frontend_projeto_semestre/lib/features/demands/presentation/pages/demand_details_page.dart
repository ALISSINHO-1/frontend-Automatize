import 'package:flutter/material.dart';

class DemandDetailsPage extends StatelessWidget {
  const DemandDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F131C),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Voltar
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Meus Projetos'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFADC6FF),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Identificação
                    const Text(
                      'DEMANDA',
                      style: TextStyle(
                        color: Color(0xFF4CD7F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Título e status
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Integração do sistema de pagamentos',
                          style: TextStyle(
                            color: Color(0xFFDFE2EE),
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4D8EFF).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'EM DESENVOLVIMENTO',
                            style: TextStyle(
                              color: Color(0xFFADC6FF),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Card principal
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181C24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF424754),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Descrição',
                            style: TextStyle(
                              color: Color(0xFFDFE2EE),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Implementação e integração do novo fluxo de '
                            'pagamentos do sistema, incluindo validações e '
                            'comunicação com os serviços necessários.',
                            style: TextStyle(
                              color: Color(0xFFC2C6D6),
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 32),

                          const Divider(
                            color: Color(0xFF424754),
                          ),

                          const SizedBox(height: 24),

                          // Responsável e estado
                          const Wrap(
                            spacing: 80,
                            runSpacing: 24,
                            children: [
                              _InformationItem(
                                label: 'RESPONSÁVEL',
                                value: 'Luis Felipe',
                                icon: Icons.person_outline,
                              ),
                              _InformationItem(
                                label: 'ESTADO',
                                value: 'Desenvolvimento',
                                icon: Icons.sync,
                              ),
                            ],
                          ),

                          const SizedBox(height: 36),

                          // Progresso
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progresso',
                                style: TextStyle(
                                  color: Color(0xFFDFE2EE),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '75%',
                                style: TextStyle(
                                  color: Color(0xFFADC6FF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: const LinearProgressIndicator(
                              value: 0.75,
                              minHeight: 10,
                              backgroundColor: Color(0xFF31353E),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4D8EFF),
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          const Divider(
                            color: Color(0xFF424754),
                          ),

                          const SizedBox(height: 24),

                          // Datas
                          const Wrap(
                            spacing: 80,
                            runSpacing: 24,
                            children: [
                              _InformationItem(
                                label: 'CRIADA EM',
                                value: '01/10/2026',
                                icon: Icons.calendar_today_outlined,
                              ),
                              _InformationItem(
                                label: 'ATUALIZADA EM',
                                value: '06/10/2026',
                                icon: Icons.update,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Aviso temporário
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2028),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF4CD7F6),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Os dados exibidos nesta versão são temporários '
                              'e serão substituídos pelos dados retornados pela API.',
                              style: TextStyle(
                                color: Color(0xFFC2C6D6),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InformationItem extends StatelessWidget {
  const _InformationItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF4D8EFF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFADC6FF),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8C909F),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFDFE2EE),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}