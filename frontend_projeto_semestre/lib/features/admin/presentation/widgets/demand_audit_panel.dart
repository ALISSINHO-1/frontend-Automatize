import 'package:flutter/material.dart';

import '../../../../shared/widgets/main_layout.dart';
import '../../data/models/auditoria_model.dart';
import '../admin_style.dart';

/// Auditoria da demanda (SCRUM-79): evidências numa seção própria e o
/// registro de ações em linha do tempo, como no preview.
class DemandAuditPanel extends StatefulWidget {
  const DemandAuditPanel({super.key, required this.carregar});

  /// Normalmente `AdminDemandService.listarAuditoria` já com o id da demanda.
  final Future<List<AuditoriaModel>> Function() carregar;

  @override
  State<DemandAuditPanel> createState() => _DemandAuditPanelState();
}

class _DemandAuditPanelState extends State<DemandAuditPanel> {
  late Future<List<AuditoriaModel>> _registros = widget.carregar();

  void _recarregar() => setState(() => _registros = widget.carregar());

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AdminStyle.caixa(),
      child: FutureBuilder<List<AuditoriaModel>>(
        future: _registros,
        builder: (context, snapshot) {
          final cabecalho = Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auditoria e evidências',
                      style: AdminStyle.tituloCard,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ações registradas pelo backend sobre esta demanda.',
                      style: AdminStyle.subtitulo,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _recarregar,
                tooltip: 'Atualizar auditoria',
                color: AutomatizeColors.muted,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          );

          if (snapshot.connectionState != ConnectionState.done) {
            return Column(
              children: [
                cabecalho,
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cabecalho,
                const SizedBox(height: 12),
                Text(
                  'Não foi possível carregar a auditoria: ${snapshot.error}',
                  style: const TextStyle(color: AutomatizeColors.danger),
                ),
              ],
            );
          }

          final registros = snapshot.data ?? const <AuditoriaModel>[];
          final evidencias = registros.where((r) => r.isEvidencia).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cabecalho,
              const SizedBox(height: 18),
              _Secao('Evidências (${evidencias.length})'),
              if (evidencias.isEmpty)
                const Text(
                  'Nenhuma evidência enviada.',
                  style: AdminStyle.subtitulo,
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [for (final r in evidencias) _Evidencia(r)],
                ),
              const Divider(height: 36, color: AdminStyle.cardBorda),
              _Secao('Registro de ações (${registros.length})'),
              if (registros.isEmpty)
                const Text(
                  'Nenhuma ação registrada.',
                  style: AdminStyle.subtitulo,
                )
              else
                for (var i = 0; i < registros.length; i++)
                  _EventoLinhaDoTempo(
                    registros[i],
                    ultimo: i == registros.length - 1,
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      texto,
      style: const TextStyle(
        color: AutomatizeColors.text,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Evidencia extends StatelessWidget {
  const _Evidencia(this.registro);

  final AuditoriaModel registro;

  @override
  Widget build(BuildContext context) => Container(
    width: 280,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AdminStyle.fundo,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AdminStyle.cardBorda),
    ),
    child: Row(
      children: [
        const Icon(Icons.description_rounded, color: AdminStyle.destaqueClaro),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                registro.nomeArquivo ?? 'Arquivo sem nome',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AutomatizeColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                [
                  if (registro.tamanhoBytes != null)
                    formatarTamanho(registro.tamanhoBytes!),
                  if (registro.createdAt != null)
                    formatarDataHora(registro.createdAt!),
                ].join(' · '),
                style: const TextStyle(
                  color: AutomatizeColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EventoLinhaDoTempo extends StatelessWidget {
  const _EventoLinhaDoTempo(this.registro, {required this.ultimo});

  final AuditoriaModel registro;
  final bool ultimo;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 22,
          child: Column(
            children: [
              const SizedBox(height: 4),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: registro.isEvidencia
                      ? AutomatizeColors.success
                      : AdminStyle.destaque,
                ),
              ),
              if (!ultimo)
                const Expanded(
                  child: VerticalDivider(
                    width: 2,
                    thickness: 2,
                    color: AdminStyle.cardBorda,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  registro.rotulo,
                  style: const TextStyle(
                    color: AutomatizeColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (registro.createdAt != null)
                      formatarDataHora(registro.createdAt!),
                    // Só há UUID do autor; nomes dependem de rota de usuários no backend.
                    'por ${registro.usuarioId ?? 'sistema'}',
                  ].join(' · '),
                  style: const TextStyle(
                    color: AutomatizeColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

String formatarTamanho(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String formatarDataHora(DateTime data) {
  final local = data.toLocal();
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(local.day)}/${dois(local.month)}/${local.year} '
      '${dois(local.hour)}:${dois(local.minute)}';
}
