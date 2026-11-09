
import 'package:flutter/material.dart';

import '../../data/services/ocorrencia_cliente_service.dart';

class ClienteOcorrenciasPage extends StatefulWidget {
  const ClienteOcorrenciasPage({
    super.key,
    required this.demandaId,
    this.service,
  });

  final String demandaId;
  final OcorrenciaClienteService? service;

  @override
  State<ClienteOcorrenciasPage> createState() =>
      _ClienteOcorrenciasPageState();
}

class _ClienteOcorrenciasPageState
    extends State<ClienteOcorrenciasPage> {
  final _descricaoController = TextEditingController();

  late OcorrenciaClienteService _service;
  late bool _ownsService;
  late Future<List<Map<String, dynamic>>> _lista;

  String _tipo = 'ERRO';
  String? _erroEnvio;
  String? _mensagemSucesso;

  bool _enviando = false;
  bool _resultadoIncerto = false;

  @override
  void initState() {
    super.initState();

    _ownsService = widget.service == null;
    _service = widget.service ??
        OcorrenciaClienteService();

    _lista = _service.listar(widget.demandaId);
  }

  @override
  void didUpdateWidget(
    covariant ClienteOcorrenciasPage oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.demandaId != widget.demandaId ||
        oldWidget.service != widget.service) {
      if (_ownsService) {
        _service.dispose();
      }

      _ownsService = widget.service == null;
      _service = widget.service ??
          OcorrenciaClienteService();

      _descricaoController.clear();
      _erroEnvio = null;
      _mensagemSucesso = null;
      _resultadoIncerto = false;
      _lista = _service.listar(widget.demandaId);
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();

    if (_ownsService) {
      _service.dispose();
    }

    super.dispose();
  }

  void _atualizar() {
    setState(() {
      _lista = _service.listar(widget.demandaId);
    });
  }

  bool get _descricaoValida {
    final tamanho = _descricaoController.text.trim().length;
    return tamanho >= 10 && tamanho <= 2000;
  }

  Future<void> _enviar() async {
    if (_enviando ||
        _resultadoIncerto ||
        !_descricaoValida) {
      return;
    }

    setState(() {
      _enviando = true;
      _erroEnvio = null;
      _mensagemSucesso = null;
    });

    try {
      await _service.criar(
        demandaId: widget.demandaId,
        tipo: _tipo,
        descricao: _descricaoController.text,
      );

      if (!mounted) return;

      setState(() {
        _descricaoController.clear();
        _mensagemSucesso =
            'Ocorrência registrada pela API.';
        _lista = _service.listar(widget.demandaId);
      });
    } on OcorrenciaClienteException catch (erro) {
      if (!mounted) return;

      setState(() {
        _erroEnvio = erro.mensagem;
        _resultadoIncerto = erro.resultadoIncerto;
      });

      if (erro.statusCode == 409) {
        _atualizar();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erroEnvio =
            'Não foi possível confirmar o envio. '
            'Consulte as ocorrências antes de tentar '
            'novamente.';
        _resultadoIncerto = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  String _formatarData(dynamic valor) {
    final data = DateTime.tryParse(
      valor?.toString() ?? '',
    );

    if (data == null) {
      return 'Data não informada';
    }

    final local = data.toLocal();

    String dois(int numero) =>
        numero.toString().padLeft(2, '0');

    return '${dois(local.day)}/'
        '${dois(local.month)}/${local.year} '
        '${dois(local.hour)}:${dois(local.minute)}';
  }

  String _texto(dynamic valor) {
    final texto = valor?.toString().trim() ?? '';
    return texto.isEmpty ? 'Não informado' : texto;
  }

  Widget _formulario() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Abrir ocorrência',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 16),

            const Text('Tipo da ocorrência'),

            DropdownButton<String>(
              value: _tipo,
              isExpanded: true,
              onChanged: _enviando || _resultadoIncerto
                  ? null
                  : (valor) {
                      if (valor != null) {
                        setState(() {
                          _tipo = valor;
                        });
                      }
                    },
              items: const [
                DropdownMenuItem(
                  value: 'ERRO',
                  child: Text('Erro encontrado'),
                ),
                DropdownMenuItem(
                  value: 'SOLICITACAO_CORRECAO',
                  child: Text('Solicitação de correção'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _descricaoController,
              maxLines: 5,
              maxLength: 2000,
              enabled: !_enviando && !_resultadoIncerto,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText:
                    'Explique o problema encontrado...',
                helperText:
                    'Mínimo de 10 e máximo de 2.000 caracteres.',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            if (_erroEnvio != null) ...[
              Text(
                _erroEnvio!,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_mensagemSucesso != null) ...[
              Text(
                _mensagemSucesso!,
                style: const TextStyle(
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_resultadoIncerto) ...[
              const Text(
                'O resultado do envio é incerto. '
                'Para evitar uma ocorrência duplicada, '
                'não envie novamente nesta tela.',
                style: TextStyle(
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 12),
            ],

            FilledButton.icon(
              onPressed: _enviando ||
                      _resultadoIncerto ||
                      !_descricaoValida
                  ? null
                  : _enviar,
              icon: const Icon(Icons.send_outlined),
              label: Text(
                _enviando
                    ? 'Enviando...'
                    : 'Registrar ocorrência',
              ),
            ),

            if (_enviando) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cardOcorrencia(Map<String, dynamic> ocorrencia) {
    final resolvida = ocorrencia['resolvida'] == true;

    final tipo = ocorrencia['tipo'] == 'ERRO'
        ? 'Erro'
        : ocorrencia['tipo'] == 'SOLICITACAO_CORRECAO'
            ? 'Solicitação de correção'
            : _texto(ocorrencia['tipo']);

    final descricaoResolucao =
        ocorrencia['descricao_resolucao']
                ?.toString()
                .trim() ??
            '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  resolvida
                      ? Icons.check_circle_outline
                      : Icons.pending_actions,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tipo,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
                Text(
                  resolvida ? 'Resolvida' : 'Aberta',
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(_texto(ocorrencia['descricao'])),

            const SizedBox(height: 12),

            Text(
              'Criada em: '
              '${_formatarData(ocorrencia['created_at'])}',
            ),

            const SizedBox(height: 6),

            Text(
              'Autor (ID): '
              '${_texto(ocorrencia['autor_id'])}',
            ),

            if (descricaoResolucao.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Tratamento técnico',
                style:
                    Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(descricaoResolucao),
              const SizedBox(height: 8),
              Text(
                'Resolvida em: '
                '${_formatarData(ocorrencia['resolvida_em'])}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F131C),
      appBar: AppBar(
        title: const Text('Ocorrências da demanda'),
        actions: [
          IconButton(
            tooltip: 'Atualizar ocorrências',
            onPressed: _enviando ? null : _atualizar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _lista,
        builder: (context, snapshot) {
          if (snapshot.connectionState !=
              ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _atualizar,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final ocorrencias =
              snapshot.data ?? <Map<String, dynamic>>[];

          return Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Demanda: ${widget.demandaId}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),

                  const SizedBox(height: 16),

                  _formulario(),

                  const SizedBox(height: 24),

                  Text(
                    'Acompanhamento das ocorrências',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),

                  const SizedBox(height: 12),

                  if (ocorrencias.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Nenhuma ocorrência registrada.',
                        ),
                      ),
                    ),

                  for (final ocorrencia in ocorrencias)
                    _cardOcorrencia(ocorrencia),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
