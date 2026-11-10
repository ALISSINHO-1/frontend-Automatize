import 'package:flutter/material.dart';

import '../../data/models/pedido_model.dart';
import '../../data/services/homologacao_cliente_service.dart';
import '../widgets/anexos_homologacao_card.dart';
import '../widgets/demand_homologation_card.dart';

class DemandHomologationPage extends StatefulWidget {
  const DemandHomologationPage({super.key, required this.pedido});

  final PedidoModel pedido;

  @override
  State<DemandHomologationPage> createState() => _DemandHomologationPageState();
}

class _DemandHomologationPageState extends State<DemandHomologationPage> {
  final _versaoController = TextEditingController();
  final _declaracaoController = TextEditingController();
  final _motivoController = TextEditingController();

  final HomologacaoClienteService _service = HomologacaoClienteService();

  bool concordou = false;
  bool processando = false;
  bool enviandoAnexo = false;
  bool consultando = true;
  bool decisaoRegistrada = false;
  bool resultadoIncerto = false;

  String? statusAtual;
  String? erroConsulta;
  String? erroOperacao;

  bool get _homologacaoAberta =>
      statusAtual == 'HOMOLOGACAO' && !decisaoRegistrada && !resultadoIncerto;

  bool get _podeDecidir =>
      _homologacaoAberta && !processando && !consultando && !enviandoAnexo;

  bool get _podeAprovar =>
      _podeDecidir &&
      concordou &&
      _versaoController.text.trim().isNotEmpty &&
      _versaoController.text.trim().length <= 50 &&
      _declaracaoController.text.trim().length >= 10;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _atualizarStatus();
      }
    });
  }

  @override
  void dispose() {
    _versaoController.dispose();
    _declaracaoController.dispose();
    _motivoController.dispose();
    _service.dispose();

    super.dispose();
  }

  // Consulta o status real, sem confiar apenas no pedido
  // recebido pela navegação.
  Future<void> _atualizarStatus() async {
    if (!mounted || enviandoAnexo) return;

    setState(() {
      consultando = true;
      erroConsulta = null;
      statusAtual = null;
    });

    try {
      final dados = await _service.consultar(widget.pedido.id);

      if (!mounted) return;

      final status = dados['status']?.toString().trim().toUpperCase();

      if (status == null || status.isEmpty) {
        throw const FormatException('A API não informou o estado da demanda.');
      }

      setState(() {
        statusAtual = status;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        erroConsulta = erro.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          consultando = false;
        });
      }
    }
  }

  Future<bool> _confirmar({
    required String titulo,
    required String mensagem,
    required String acao,
  }) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(acao),
            ),
          ],
        );
      },
    );

    return confirmado == true;
  }

  Future<void> _registrarDecisao(Future<void> Function() enviar) async {
    if (!_podeDecidir) return;

    setState(() {
      processando = true;
      erroOperacao = null;
    });

    try {
      await enviar();

      if (!mounted) return;

      setState(() {
        decisaoRegistrada = true;
      });

      // Após o POST, consulta o estado persistido.
      await _atualizarStatus();
    } on HomologacaoClienteException catch (erro) {
      if (!mounted) return;

      setState(() {
        erroOperacao = erro.mensagem;
        resultadoIncerto = erro.resultadoIncerto;
      });

      // Uma demanda pode ter mudado de estado
      // enquanto o cliente confirmava.
      if (erro.statusCode == 409) {
        await _atualizarStatus();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        erroOperacao =
            'Não foi possível confirmar o resultado. '
            'Consulte o estado da demanda antes '
            'de tentar novamente.';

        // Evita novo envio após uma falha inesperada
        // cujo resultado pode ser desconhecido.
        resultadoIncerto = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          processando = false;
        });
      }
    }
  }

  // POST /demandas/{id}/aceite
  Future<void> _aprovar() async {
    if (!_podeAprovar) return;

    final versao = _versaoController.text.trim();
    final declaracao = _declaracaoController.text.trim();

    final confirmado = await _confirmar(
      titulo: 'Confirmar aprovação',
      mensagem:
          'Você confirma o aceite formal da versão '
          '$versao desta entrega? '
          'Esta decisão será registrada na API.',
      acao: 'Aprovar entrega',
    );

    if (!mounted || !confirmado || !_podeAprovar) {
      return;
    }

    await _registrarDecisao(
      () => _service.aprovar(
        id: widget.pedido.id,
        versaoEntregavel: versao,
        declaracaoAceite: declaracao,
      ),
    );
  }

  // POST /demandas/{id}/rejeicao
  Future<void> _solicitarAjustes() async {
    if (!_podeDecidir) return;

    _motivoController.clear();

    final motivo = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, atualizarDialogo) {
            final valido = _motivoController.text.trim().length >= 10;

            return AlertDialog(
              title: const Text('Solicitar ajustes'),
              content: SizedBox(
                width: 420,
                child: TextField(
                  controller: _motivoController,
                  maxLines: 5,
                  maxLength: 500,
                  onChanged: (_) {
                    atualizarDialogo(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: 'Motivo da rejeição',
                    hintText: 'Explique a inconformidade encontrada...',
                    helperText: 'Mínimo de 10 caracteres',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: valido
                      ? () =>
                            Navigator.of(dialogContext)
                                .pop(_motivoController.text.trim())
                      : null,
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || motivo == null || !_podeDecidir) {
      return;
    }

    final confirmado = await _confirmar(
      titulo: 'Confirmar solicitação de ajustes',
      mensagem:
          'Deseja registrar a rejeição desta entrega '
          'com o motivo informado? '
          'A decisão será enviada à API.',
      acao: 'Solicitar ajustes',
    );

    if (!mounted || !confirmado || !_podeDecidir) {
      return;
    }

    await _registrarDecisao(
      () => _service.rejeitar(id: widget.pedido.id, motivo: motivo),
    );
  }

  void _voltar() {
    Navigator.of(context).pop(decisaoRegistrada);
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;

    return Scaffold(
      backgroundColor: const Color(0xFF0F131C),
      appBar: AppBar(
        title: const Text('Homologação da entrega'),
        backgroundColor: const Color(0xFF181C24),
        foregroundColor: const Color(0xFFDFE2EE),
        leading: IconButton(
          tooltip: 'Voltar ao acompanhamento',
          icon: const Icon(Icons.arrow_back),
          onPressed: _voltar,
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar estado',
            icon: const Icon(Icons.refresh),
            onPressed: processando || consultando || enviandoAnexo
                ? null
                : _atualizarStatus,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                '${pedido.codigoIdentificador ?? pedido.id} '
                '• ${pedido.titulo}',
                style: const TextStyle(
                  color: Color(0xFFDFE2EE),
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Confira a entrega antes de registrar '
                'sua avaliação.',
                style: TextStyle(color: Color(0xFFC2C6D6)),
              ),

              const SizedBox(height: 24),

              // Estado consultado diretamente na API.
              Card(
                color: const Color(0xFF181C24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado atual da demanda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (consultando) const LinearProgressIndicator(),

                      if (!consultando && statusAtual != null)
                        Text(
                          statusAtual!,
                          style: const TextStyle(
                            color: Colors.lightBlueAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      if (erroConsulta != null)
                        Text(
                          erroConsulta!,
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),

                      if (!consultando &&
                          !decisaoRegistrada &&
                          statusAtual != null &&
                          statusAtual != 'HOMOLOGACAO')
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'A demanda não está em homologação. '
                            'Nenhuma decisão pode ser enviada.',
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Dados necessários para o aceite formal.
              if (_homologacaoAberta) ...[
                Card(
                  color: const Color(0xFF181C24),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aprovação formal',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          pedido.descricao,
                          style: const TextStyle(color: Color(0xFFC2C6D6)),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _versaoController,
                          enabled: _podeDecidir,
                          maxLength: 50,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Versão do entregável',
                            hintText: 'Ex.: v1.0',
                            helperText: 'Informe a versão real entregue.',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _declaracaoController,
                          enabled: _podeDecidir,
                          minLines: 2,
                          maxLines: 4,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Declaração de aceite',
                            hintText:
                                'Declaro que conferi e aprovo '
                                'a entrega informada.',
                            helperText: 'Mínimo de 10 caracteres',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: concordou,
                          onChanged: _podeDecidir
                              ? (valor) =>
                                    setState(() => concordou = valor ?? false)
                              : null,
                          title: const Text(
                            'Li, conferi e concordo com '
                            'a entrega informada.',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],

              if (_homologacaoAberta) ...[
                AnexosHomologacaoCard(
                  key: ValueKey(pedido.id),
                  demandaId: pedido.id,
                  habilitado: _podeDecidir,
                  onEnviando: (valor) => setState(() => enviandoAnexo = valor),
                ),
                const SizedBox(height: 16),
                DemandHomologationCard(
                  status: statusAtual!,
                  onAprovar: _podeAprovar ? _aprovar : null,
                  onReprovar: _podeDecidir ? _solicitarAjustes : null,
                ),
              ],

              if (processando) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 8),
                const Center(child: Text('Registrando decisão na API...')),
              ],

              if (erroOperacao != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      erroOperacao!,
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                  ),
                ),
              ],

              // Esta mensagem só aparece se o POST
              // recebeu a confirmação de sucesso da API.
              if (decisaoRegistrada) ...[
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.greenAccent),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Decisão registrada pela API',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          statusAtual == null
                              ? 'A decisão foi registrada, '
                                    'mas não foi possível consultar '
                                    'o estado atualizado.'
                              : 'Estado retornado após a decisão: '
                                    '$statusAtual',
                        ),

                        const SizedBox(height: 16),

                        FilledButton.icon(
                          onPressed: _voltar,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Voltar ao acompanhamento'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (resultadoIncerto) ...[
                const SizedBox(height: 16),
                const Text(
                  'O envio não pôde ser confirmado. '
                  'Para evitar duplicidade, esta tela '
                  'não permitirá repetir a decisão. '
                  'Consulte o estado atualizado.',
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
