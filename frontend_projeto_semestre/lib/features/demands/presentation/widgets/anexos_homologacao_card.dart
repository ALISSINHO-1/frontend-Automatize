import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

import '../../../../app/app.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/storage/local_storage_service.dart';

class AnexosHomologacaoCard extends StatefulWidget {
  const AnexosHomologacaoCard({
    super.key,
    required this.demandaId,
    required this.habilitado,
    this.exibirEnvio = true,
    this.onEnviando,
  });
  final String demandaId;
  final bool habilitado;
  final bool exibirEnvio;
  final ValueChanged<bool>? onEnviando;
  @override
  State<AnexosHomologacaoCard> createState() => _AnexosHomologacaoCardState();
}

class _AnexosHomologacaoCardState extends State<AnexosHomologacaoCard> {
  static const int _limiteBytes = 10 * 1024 * 1024;
  static const _formatos = ['png', 'jpg', 'jpeg', 'pdf'];
  static const _tempoLimite = Duration(seconds: 30);
  final http.Client _client = AuthInterceptorClient(
    navigatorKey: appNavigatorKey,
  );
  PlatformFile? _selecionado;
  Uint8List? _bytesSelecionados;
  Uint8List? _previaSelecionada;
  String? _erroPreviaSelecionada;
  List<Map<String, dynamic>> _anexos = [];
  final Map<String, Future<Uint8List>> _previasRemotas = {};
  bool _consultando = false;
  bool _selecionando = false;
  bool _enviando = false;
  bool _resultadoIncerto = false;
  String? _erro;
  String? _erroConsulta;
  String? _sucesso;
  String get _caminho =>
      '${ApiPaths.demandas}/'
      '${Uri.encodeComponent(widget.demandaId)}/evidencias';
  String get _caminhoLista =>
      '${ApiPaths.demandas}/'
      '${Uri.encodeComponent(widget.demandaId)}/anexos';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _consultarAnexos();
      }
    });
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  static String _extensao(String nome) {
    final indice = nome.lastIndexOf('.');
    return indice < 0 ? '' : nome.substring(indice + 1).toLowerCase();
  }

  static String _tamanhoFormatado(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _mensagemHttp(int status) => switch (status) {
    400 ||
    413 ||
    422 => 'Arquivo recusado. Verifique o formato e o limite de 10 MB.',
    401 => 'Sessão expirada. Entre novamente.',
    403 => 'Sem permissão para acessar este arquivo.',
    404 => 'Demanda ou anexo não encontrado.',
    409 => 'O estado da demanda não permite esta operação.',
    503 => 'Armazenamento dos arquivos indisponível.',
    _ => 'Falha na API (HTTP $status).',
  };
  Future<String> _tokenAtual() async {
    final token = await LocalStorageService.getToken();
    if (token == null || token.trim().isEmpty) {
      throw const _FalhaDefinitiva('Faça login para acessar os anexos.');
    }
    return token;
  }

  /// Converte a primeira página do PDF em PNG usando pdfx.
  Future<Uint8List> _primeiraPaginaPdf(Uint8List bytes) async {
    PdfDocument? documento;
    PdfPage? pagina;
    try {
      documento = await PdfDocument.openData(bytes);
      if (documento.pagesCount < 1) {
        throw const FormatException('O PDF não contém páginas.');
      }
      pagina = await documento.getPage(1);
      final largura = 550.0;
      final altura = largura * pagina.height / pagina.width;
      final imagem = await pagina.render(
        width: largura,
        height: altura,
        format: PdfPageImageFormat.png,
      );
      if (imagem == null || imagem.bytes.isEmpty) {
        throw const FormatException('Não foi possível renderizar o PDF.');
      }
      return imagem.bytes;
    } finally {
      if (pagina != null) {
        await pagina.close();
      }
      if (documento != null) {
        await documento.close();
      }
    }
  }

  /// Busca os anexos já registrados no backend.
  Future<void> _consultarAnexos() async {
    if (!mounted || _consultando) return;
    final idConsultado = widget.demandaId;
    setState(() {
      _consultando = true;
      _erroConsulta = null;
    });
    try {
      final token = await _tokenAtual();
      final response = await _client
          .get(
            AppConfig.apiUri(_caminhoLista),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_tempoLimite);
      if (await LocalStorageService.getToken() != token) {
        throw const _FalhaDefinitiva('A sessão mudou durante a consulta.');
      }
      if (response.statusCode != 200) {
        throw _FalhaDefinitiva(_mensagemHttp(response.statusCode));
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! List) {
        throw const FormatException('Resposta de anexos inválida.');
      }
      final anexos = data.map<Map<String, dynamic>>((item) {
        if (item is! Map) {
          throw const FormatException('Item de anexo inválido.');
        }
        final anexo = Map<String, dynamic>.from(item);
        if (anexo['pedido_id']?.toString() != idConsultado) {
          throw const FormatException('Anexo de outra demanda.');
        }
        return anexo;
      }).toList();
      if (!mounted || widget.demandaId != idConsultado) {
        return;
      }
      setState(() {
        _anexos = anexos;
        _previasRemotas.clear();
      });
    } catch (e) {
      if (!mounted || widget.demandaId != idConsultado) {
        return;
      }
      setState(() {
        _erroConsulta = e.toString();
      });
    } finally {
      if (mounted && widget.demandaId == idConsultado) {
        setState(() {
          _consultando = false;
        });
      }
    }
  }

  /// Obtém uma URL temporária autorizada e baixa os bytes
  /// somente para a prévia.
  /// O Bearer é enviado APENAS à API.
  Future<Uint8List> _baixarPreviaAnexo(Map<String, dynamic> anexo) async {
    final token = await _tokenAtual();
    final idDemanda = widget.demandaId;
    final idAnexo = anexo['id']?.toString() ?? '';
    if (idAnexo.isEmpty) {
      throw const FormatException('Anexo sem identificador.');
    }
    final caminhoAcesso =
        '${ApiPaths.demandas}/'
        '${Uri.encodeComponent(idDemanda)}/'
        'anexos/${Uri.encodeComponent(idAnexo)}/acesso';
    final respostaAcesso = await _client
        .get(
          AppConfig.apiUri(caminhoAcesso),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(_tempoLimite);
    if (await LocalStorageService.getToken() != token) {
      throw const _FalhaDefinitiva('A sessão mudou durante a consulta.');
    }
    if (respostaAcesso.statusCode != 200) {
      throw _FalhaDefinitiva(_mensagemHttp(respostaAcesso.statusCode));
    }
    final dados = jsonDecode(utf8.decode(respostaAcesso.bodyBytes));
    if (dados is! Map || dados['url'] is! String) {
      throw const FormatException('Link de acesso ao arquivo inválido.');
    }
    final url = Uri.tryParse(dados['url'] as String);
    if (url == null ||
        !url.hasAuthority ||
        (url.scheme != 'https' &&
            !(url.scheme == 'http' &&
                (url.host == 'localhost' || url.host == '127.0.0.1')))) {
      throw const FormatException('Endereço de arquivo não seguro.');
    }
    // O link temporário já está assinado.
    // O token não é enviado ao armazenamento.
    final respostaArquivo = await http.get(url).timeout(_tempoLimite);
    if (await LocalStorageService.getToken() != token) {
      throw const _FalhaDefinitiva('A sessão mudou durante a consulta.');
    }
    if (respostaArquivo.statusCode != 200) {
      throw _FalhaDefinitiva(
        'Não foi possível obter o documento '
        '(HTTP ${respostaArquivo.statusCode}).',
      );
    }
    if (respostaArquivo.bodyBytes.isEmpty ||
        respostaArquivo.bodyBytes.length > _limiteBytes) {
      throw const FormatException('Documento vazio ou maior que 10 MB.');
    }
    final nome = anexo['nome_arquivo']?.toString() ?? '';
    final extensao = _extensao(nome);
    if (extensao == 'pdf') {
      return _primeiraPaginaPdf(respostaArquivo.bodyBytes);
    }
    if (!['png', 'jpg', 'jpeg'].contains(extensao)) {
      throw const FormatException('Prévia não disponível para este formato.');
    }
    return respostaArquivo.bodyBytes;
  }

  /// Seleciona um PNG/JPG/PDF e gera sua miniatura.
  Future<void> _selecionar() async {
    if (_selecionando || _enviando || _resultadoIncerto || !widget.habilitado) {
      return;
    }
    setState(() {
      _selecionando = true;
      _erro = null;
      _sucesso = null;
      _erroPreviaSelecionada = null;
    });
    try {
      final arquivos = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _formatos,
      );
      if (arquivos.isEmpty) return;
      final arquivo = arquivos.first;
      final extensao = arquivo.extension?.toLowerCase();
      final tamanho = await arquivo.length();
      if (!_formatos.contains(extensao) ||
          arquivo.name.trim().isEmpty ||
          arquivo.name.length > 255 ||
          arquivo.name.contains('/') ||
          arquivo.name.contains('\\')) {
        throw const _FalhaDefinitiva(
          'Selecione um arquivo PNG, JPG, JPEG ou PDF válido.',
        );
      }
      if (tamanho == null || tamanho <= 0 || tamanho > _limiteBytes) {
        throw const _FalhaDefinitiva('O limite é de 10 MB por arquivo.');
      }
      final bytesLidos = await arquivo.readAsBytes();
      if (bytesLidos.isEmpty || bytesLidos.length > _limiteBytes) {
        throw const _FalhaDefinitiva('Arquivo vazio ou maior que 10 MB.');
      }
      // O pdfx pode transferir o buffer para o renderizador no navegador.
      // Criamos duas cópias distintas para preservar o arquivo original.
      final bytesParaUpload = Uint8List.fromList(bytesLidos);
      final bytesParaPrevia = Uint8List.fromList(bytesLidos);
      if (!mounted) return;
      setState(() {
        _selecionado = arquivo;
        _bytesSelecionados = bytesParaUpload;
        _previaSelecionada = null;
        _erroPreviaSelecionada = null;
      });
      try {
        final previa = extensao == 'pdf'
            ? await _primeiraPaginaPdf(bytesParaPrevia)
            : bytesParaPrevia;
        if (!mounted) return;
        setState(() {
          _previaSelecionada = previa;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _erroPreviaSelecionada =
              'Não foi possível gerar a miniatura deste arquivo.';
        });
      }
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _selecionando = false;
        });
      }
    }
  }

  /// Envia o arquivo original para a API.
  Future<void> _enviar() async {
    final arquivo = _selecionado;
    final bytes = _bytesSelecionados;
    if (arquivo == null ||
        bytes == null ||
        _enviando ||
        _consultando ||
        _selecionando ||
        _resultadoIncerto ||
        !widget.habilitado) {
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
      _sucesso = null;
    });
    widget.onEnviando?.call(true);
    final idEnviado = widget.demandaId;
    try {
      final token = await _tokenAtual();
      if (bytes.isEmpty || bytes.length > _limiteBytes) {
        throw const _FalhaDefinitiva('Arquivo vazio ou acima de 10 MB.');
      }
      if (await LocalStorageService.getToken() != token) {
        throw const _FalhaDefinitiva('A sessão mudou antes do envio.');
      }
      final request = http.MultipartRequest('POST', AppConfig.apiUri(_caminho));
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes('arquivo', bytes, filename: arquivo.name),
      );
      final streamed = await _client.send(request).timeout(_tempoLimite);
      final response = await http.Response.fromStream(streamed)
          .timeout(_tempoLimite);
      if (await LocalStorageService.getToken() != token) {
        throw const _FalhaIndefinida('A sessão mudou durante o envio.');
      }
      if (response.statusCode >= 500) {
        throw _FalhaIndefinida(_mensagemHttp(response.statusCode));
      }
      if (response.statusCode != 201) {
        throw _FalhaDefinitiva(_mensagemHttp(response.statusCode));
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final anexoId = data is Map ? data['id']?.toString().trim() : null;
      if (data is! Map ||
          anexoId == null ||
          anexoId.isEmpty ||
          data['pedido_id']?.toString() != idEnviado) {
        throw const _FalhaIndefinida('O servidor não confirmou o anexo.');
      }
      if (!mounted || widget.demandaId != idEnviado) {
        return;
      }
      setState(() {
        _sucesso = 'Anexo enviado: ${arquivo.name}';
        _selecionado = null;
        _bytesSelecionados = null;
        _previaSelecionada = null;
        _erroPreviaSelecionada = null;
      });
      await _consultarAnexos();
    } on _FalhaDefinitiva catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.mensagem;
        });
      }
    } on _FalhaIndefinida catch (e) {
      if (mounted) {
        setState(() {
          _erro =
              '${e.mensagem} Confira a lista '
              'antes de tentar novamente.';
          _resultadoIncerto = true;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _erro =
              'Tempo esgotado. Confira a lista '
              'antes de reenviar.';
          _resultadoIncerto = true;
        });
      }
    } on http.ClientException {
      if (mounted) {
        setState(() {
          _erro =
              'Falha de conexão. Confira a lista '
              'antes de reenviar.';
          _resultadoIncerto = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _erro =
              'Não foi possível confirmar o envio. '
              'Confira a lista.';
          _resultadoIncerto = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
        widget.onEnviando?.call(false);
      }
    }
  }

  /// Exibe a imagem ampliada.
  void _ampliarImagem(Uint8List bytes, String nome) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 800,
          height: 650,
          child: Column(
            children: [
              ListTile(
                title: Text(nome, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  tooltip: 'Fechar',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.7,
                  maxScale: 4,
                  child: Center(
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Exibe a miniatura da imagem ou PDF.
  Widget _imagemDocumento(Uint8List bytes, String nome) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Center(
              child: Text(
                'Não foi possível exibir a imagem.',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _ampliarImagem(bytes, nome),
          icon: const Icon(Icons.zoom_in),
          label: const Text('Ampliar documento'),
        ),
      ],
    );
  }

  /// Exibe a miniatura de um anexo registrado.
  Widget _anexoRegistrado(Map<String, dynamic> anexo) {
    final id = anexo['id']?.toString() ?? '';
    final nome = anexo['nome_arquivo']?.toString() ?? 'Arquivo';
    final tamanho = anexo['tamanho_bytes'];
    final future = _previasRemotas.putIfAbsent(
      id,
      () => _baixarPreviaAnexo(anexo),
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (tamanho is num) Text(_tamanhoFormatado(tamanho.toInt())),
            const SizedBox(height: 10),
            FutureBuilder<Uint8List>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text(
                    'Não foi possível carregar a prévia '
                    'deste documento. Verifique o acesso '
                    'ao armazenamento.',
                  );
                }
                return _imagemDocumento(snapshot.data!, nome);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF181C24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anexos da entrega',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.exibirEnvio
                  ? 'PNG, JPG, JPEG ou PDF (até 10 MB). '
                    'Imagens são exibidas diretamente; PDFs '
                    'mostram a primeira página.'
                  : 'Visualize os arquivos registrados na demanda. '
                    'Imagens e a primeira página dos PDFs '
                    'podem ser ampliadas.',
            ),
            const SizedBox(height: 14),
            if (widget.exibirEnvio)
              OutlinedButton.icon(
                onPressed:
                    widget.habilitado &&
                      !_selecionando &&
                      !_consultando &&
                      !_enviando &&
                      !_resultadoIncerto
                  ? _selecionar
                  : null,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _selecionando ? 'Preparando prévia...' : 'Selecionar anexo',
              ),
            ),
            if (_selecionado != null) ...[
              const SizedBox(height: 12),
              Text('Selecionado: ${_selecionado!.name}'),
              const SizedBox(height: 8),
              if (_previaSelecionada != null)
                _imagemDocumento(_previaSelecionada!, _selecionado!.name)
              else if (_erroPreviaSelecionada != null)
                Text(
                  _erroPreviaSelecionada!,
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed:
                    widget.habilitado &&
                        !_selecionando &&
                        !_enviando &&
                        !_resultadoIncerto
                    ? _enviar
                    : null,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Enviar anexo para API'),
              ),
            ],
            if (_enviando) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const Text('Enviando arquivo...'),
            ],
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(_erro!, style: const TextStyle(color: Colors.orangeAccent)),
            ],
            if (_sucesso != null) ...[
              const SizedBox(height: 10),
              Text(
                _sucesso!,
                style: const TextStyle(color: Colors.greenAccent),
              ),
            ],
            if (_resultadoIncerto)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Resultado do envio incerto. '
                  'Para evitar duplicação, não é '
                  'possível reenviar nesta tela.',
                ),
              ),
            const Divider(height: 32),
            Row(
              children: [
                const Expanded(child: Text('Anexos registrados na demanda')),
                IconButton(
                  tooltip: 'Atualizar lista',
                  onPressed: _consultando || _enviando
                      ? null
                      : _consultarAnexos,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (_consultando) const LinearProgressIndicator(),
            if (_erroConsulta != null)
              Text(
                _erroConsulta!,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            if (!_consultando && _erroConsulta == null && _anexos.isEmpty)
              const Text('Nenhum anexo registrado.'),
            if (!_consultando && _erroConsulta == null)
              for (final anexo in _anexos) _anexoRegistrado(anexo),
          ],
        ),
      ),
    );
  }
}

class _FalhaDefinitiva implements Exception {
  const _FalhaDefinitiva(this.mensagem);
  final String mensagem;
  @override
  String toString() => mensagem;
}

class _FalhaIndefinida implements Exception {
  const _FalhaIndefinida(this.mensagem);
  final String mensagem;
  @override
  String toString() => mensagem;
}
