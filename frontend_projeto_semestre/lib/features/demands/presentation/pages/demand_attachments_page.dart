
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/redesign_colors.dart';
import '../../data/models/pedido_model.dart';

class DemandAttachmentsPage extends StatefulWidget {
  const DemandAttachmentsPage({
  super.key,
  required this.pedido,
  this.fromAttachmentsHub = false,
});

  final PedidoModel pedido;
  final bool fromAttachmentsHub;

  @override
  State<DemandAttachmentsPage> createState() =>
      _DemandAttachmentsPageState();
}

class _DemandAttachmentsPageState
    extends State<DemandAttachmentsPage> {
  final List<PlatformFile> _arquivos = [];

  String? _erro;
  bool _selecionando = false;

  static const int _limiteBytes = 10 * 1024 * 1024;

  static const _extensoes = [
    'pdf',
    'png',
    'jpg',
    'jpeg',
    'doc',
    'docx',
  ];

  Future<void> _selecionarArquivos() async {
    if (_selecionando) return;

    setState(() {
      _selecionando = true;
      _erro = null;
    });

    try {
      final resultado = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _extensoes,
      );

      if (!mounted || resultado.isEmpty) return;

      final rejeitados = <String>[];
      final aceitos = <PlatformFile>[];

      for (final arquivo in resultado) {
        final extensao = arquivo.extension?.toLowerCase();
        final tamanho = (await arquivo.length()) ?? 0;

        if (!_extensoes.contains(extensao)) {
          rejeitados.add(
            '${arquivo.name}: formato não permitido',
          );
        } else if (tamanho > _limiteBytes) {
          rejeitados.add(
            '${arquivo.name}: excede 10 MB',
          );
        } else if (
            _arquivos.any((a) => a.name == arquivo.name) ||
            aceitos.any((a) => a.name == arquivo.name)) {
          rejeitados.add(
            '${arquivo.name}: já selecionado',
          );
        } else {
          aceitos.add(arquivo);
        }
      }

      if (!mounted) return;

      setState(() {
        _arquivos.addAll(aceitos);
        _erro = rejeitados.isEmpty
            ? null
            : rejeitados.join('\n');
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Não foi possível selecionar os arquivos: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _selecionando = false);
      }
    }
  }

  IconData _icone(String nome) {
    final extensao = nome.split('.').last.toLowerCase();

    if (['png', 'jpg', 'jpeg'].contains(extensao)) {
      return Icons.image_outlined;
    }

    if (extensao == 'pdf') {
      return Icons.picture_as_pdf_outlined;
    }

    return Icons.description_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;

    return Scaffold(
      backgroundColor: RedesignColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                    ),
                    label: Text(
                    widget.fromAttachmentsHub
                        ? 'Voltar à Central de Anexos'
                        : 'Voltar aos detalhes',
                  ),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          RedesignColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'ANEXOS DA DEMANDA',
                  style: TextStyle(
                    color: RedesignColors.purple,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  '${pedido.codigoIdentificador ?? pedido.id} '
                  '• ${pedido.titulo}',
                  style: const TextStyle(
                    color: RedesignColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Gerencie os arquivos associados a esta demanda.',
                  style: TextStyle(
                    color: RedesignColors.textSecondary,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 28),

                // Painel de seleção de arquivos.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 36,
                  ),
                  decoration: BoxDecoration(
                    color: RedesignColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: RedesignColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: RedesignColors.purple
                              .withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: RedesignColors.purple,
                          size: 38,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Selecione os arquivos da demanda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: RedesignColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'PDF, PNG, JPG, JPEG, DOC e DOCX'
                        ' • até 10 MB por arquivo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: RedesignColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 24),

                      FilledButton.icon(
                        onPressed: _selecionando
                            ? null
                            : _selecionarArquivos,
                        icon: Icon(
                          _selecionando
                              ? Icons.hourglass_top_rounded
                              : Icons.add_rounded,
                        ),
                        label: Text(
                          _selecionando
                              ? 'Selecionando...'
                              : 'Selecionar arquivos',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: RedesignColors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),

                      if (_selecionando) ...[
                        const SizedBox(height: 20),
                        const SizedBox(
                          width: 220,
                          child: LinearProgressIndicator(
                            color: RedesignColors.purple,
                            backgroundColor: RedesignColors.border,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (_erro != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF45232D)
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFB85A6C),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFFFA5A5),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _erro!,
                            style: const TextStyle(
                              color: Color(0xFFFFA5A5),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                Row(
                  children: [
                    const Icon(
                      Icons.folder_open_outlined,
                      color: RedesignColors.purple,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Arquivos selecionados '
                        '(${_arquivos.length})',
                        style: const TextStyle(
                          color: RedesignColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (_arquivos.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      color: RedesignColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: RedesignColors.border,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.folder_off_outlined,
                          color: RedesignColors.textSecondary,
                          size: 32,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Nenhum arquivo selecionado.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: RedesignColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._arquivos.map(
                    (arquivo) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: RedesignColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: RedesignColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: RedesignColors.purple
                                    .withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _icone(arquivo.name),
                                color: RedesignColors.purple,
                                size: 22,
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    arquivo.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color:
                                          RedesignColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Aguardando integração com a API',
                                    style: const TextStyle(
                                      color:
                                          RedesignColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            IconButton(
                              tooltip: 'Remover arquivo',
                              onPressed: () {
                                setState(() {
                                  _arquivos.remove(arquivo);
                                });
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFFFFA5A5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Aviso sobre o modo demonstrativo.
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: RedesignColors.purple
                        .withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: RedesignColors.border,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: RedesignColors.cyan,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Modo demonstrativo: os arquivos são '
                          'selecionados localmente. O envio, o progresso '
                          'real e a listagem de anexos salvos dependem '
                          'da integração com a API.',
                          style: TextStyle(
                            color: RedesignColors.textSecondary,
                            fontSize: 12,
                            height: 1.5,
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
    );
  }
}
