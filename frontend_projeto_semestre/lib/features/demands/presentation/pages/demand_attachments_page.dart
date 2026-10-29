import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/models/pedido_model.dart';

class DemandAttachmentsPage extends StatefulWidget {
  const DemandAttachmentsPage({super.key, required this.pedido});

  final PedidoModel pedido;

  @override
  State<DemandAttachmentsPage> createState() => _DemandAttachmentsPageState();
}

class _DemandAttachmentsPageState extends State<DemandAttachmentsPage> {
  final List<PlatformFile> _arquivos = [];
  String? _erro;
  bool _selecionando = false;

  static const int _limiteBytes = 10 * 1024 * 1024;
  static const _extensoes = ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'];

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
        if (!_extensoes.contains(extensao)) {
          rejeitados.add('${arquivo.name}: formato não permitido');
        } else if (((await arquivo.length()) ?? 0) > _limiteBytes) {
          rejeitados.add('${arquivo.name}: excede 10 MB');
        } else if (_arquivos.any((a) => a.name == arquivo.name) ||
            aceitos.any((a) => a.name == arquivo.name)) {
          rejeitados.add('${arquivo.name}: já selecionado');
        } else {
          aceitos.add(arquivo);
        }
      }

      if (!mounted) return;
      setState(() {
        _arquivos.addAll(aceitos);
        _erro = rejeitados.isEmpty ? null : rejeitados.join('\n');
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Não foi possível selecionar os arquivos: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _selecionando = false);
    }
  }

  IconData _icone(String nome) {
    final extensao = nome.split('.').last.toLowerCase();
    if (['png', 'jpg', 'jpeg'].contains(extensao)) {
      return Icons.image_outlined;
    }
    if (extensao == 'pdf') return Icons.picture_as_pdf_outlined;
    return Icons.description_outlined;
  }

  @override
  Widget build(BuildContext context) {
    const fundo = Color(0xFF0F131C);
    const painel = Color(0xFF181C24);
    const texto = Color(0xFFDFE2EE);
    const secundario = Color(0xFFC2C6D6);

    final pedido = widget.pedido;

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Anexos da demanda'),
        backgroundColor: painel,
        foregroundColor: texto,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                '${pedido.codigoIdentificador ?? pedido.id} • ${pedido.titulo}',
                style: const TextStyle(
                  color: texto,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Envio e listagem de anexos',
                style: TextStyle(color: secundario),
              ),
              const SizedBox(height: 24),
              Card(
                color: painel,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        color: Color(0xFF9DADFF),
                        size: 46,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Selecione os arquivos da demanda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: texto,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'PDF, PNG, JPG, JPEG, DOC e DOCX • até 10 MB por arquivo',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: secundario),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _selecionando ? null : _selecionarArquivos,
                        icon: const Icon(Icons.add),
                        label: Text(
                          _selecionando
                              ? 'Selecionando...'
                              : 'Selecionar arquivos',
                        ),
                      ),
                      if (_selecionando) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF402020),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _erro!,
                    style: const TextStyle(color: Color(0xFFFFA5A5)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Arquivos selecionados (${_arquivos.length})',
                style: const TextStyle(
                  color: texto,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_arquivos.isEmpty)
                const Card(
                  color: painel,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Nenhum arquivo selecionado.',
                        style: TextStyle(color: secundario),
                      ),
                    ),
                  ),
                )
              else
                ..._arquivos.map(
                  (arquivo) => Card(
                    color: painel,
                    child: ListTile(
                      leading: Icon(
                        _icone(arquivo.name),
                        color: const Color(0xFF9DADFF),
                      ),
                      title: Text(
                        arquivo.name,
                        style: const TextStyle(color: texto),
                      ),
                      subtitle: Text(
                        'Arquivo selecionado • Aguardando envio à API',
                        style: const TextStyle(color: secundario),
                      ),
                      trailing: IconButton(
                        tooltip: 'Remover arquivo',
                        icon: const Icon(Icons.close, color: Color(0xFFFFA5A5)),
                        onPressed: () {
                          setState(() => _arquivos.remove(arquivo));
                        },
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Modo demonstrativo: os arquivos são selecionados localmente. '
                'O envio, o progresso real e a listagem de anexos salvos '
                'dependem da integração com a API.',
                style: TextStyle(color: secundario, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
