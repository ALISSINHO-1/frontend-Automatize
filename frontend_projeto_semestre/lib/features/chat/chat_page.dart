import 'dart:async';

import 'package:flutter/material.dart';

import '../admin/data/models/usuario_atual_model.dart';
import '../admin/data/services/usuario_atual_store.dart';
import '../demands/data/models/pedido_model.dart';
import '../demands/data/services/demand_service.dart';
import 'chat_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _demandas = DemandService();
  late var _dados = _carregar();

  Future<({UsuarioAtualModel? usuario, List<PedidoModel> demandas})>
  _carregar() async {
    final usuario = await UsuarioAtualStore.instance.carregar();
    final demandas = usuario == null
        ? <PedidoModel>[]
        : await _demandas.buscarDemandas();
    return (usuario: usuario, demandas: demandas.reversed.toList());
  }

  void _atualizar() => setState(() => _dados = _carregar());

  @override
  void dispose() {
    _demandas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Chat'),
      actions: [
        IconButton(
          onPressed: _atualizar,
          tooltip: 'Atualizar demandas',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder(
      future: _dados,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: _atualizar,
              child: const Text('Falha ao carregar o chat. Tentar novamente'),
            ),
          );
        }
        final dados = snapshot.data!;
        final usuario = dados.usuario;
        final canais = usuario == null
            ? <ChatCanal>[]
            : ChatCanal.paraUsuario(usuario);
        if (usuario == null || canais.isEmpty || dados.demandas.isEmpty) {
          return const Center(child: Text('Nenhuma conversa disponível.'));
        }
        return ListView.builder(
          itemCount: dados.demandas.length,
          itemBuilder: (context, index) {
            final demanda = dados.demandas[index];
            final temTecnico = demanda.responsavelId != null;
            return ExpansionTile(
              title: Text(demanda.titulo),
              subtitle: Text(
                temTecnico
                    ? demanda.codigoIdentificador ?? 'Escolha um canal'
                    : 'Aguardando técnico responsável',
              ),
              leading: const Icon(Icons.forum_outlined),
              children: [
                for (final canal in canais)
                  ListTile(
                    enabled: temTecnico,
                    title: Text(canal.titulo),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: !temTecnico
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _ConversaPage(
                                demanda: demanda,
                                canal: canal,
                                usuario: usuario,
                              ),
                            ),
                          ),
                  ),
              ],
            );
          },
        );
      },
    ),
  );
}

class _ConversaPage extends StatefulWidget {
  const _ConversaPage({
    required this.demanda,
    required this.canal,
    required this.usuario,
  });

  final PedidoModel demanda;
  final ChatCanal canal;
  final UsuarioAtualModel usuario;

  @override
  State<_ConversaPage> createState() => _ConversaPageState();
}

class _ConversaPageState extends State<_ConversaPage> {
  final _chat = ChatService();
  final _texto = TextEditingController();
  List<ChatMensagem>? _mensagens;
  String? _antesDe;
  String? _erro;
  bool _carregando = false;
  bool _enviando = false;
  bool _acessoEncerrado = false;
  bool _vendoHistorico = false;
  late final Timer _atualizacao;

  @override
  void initState() {
    super.initState();
    _carregar();
    _atualizacao = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_vendoHistorico &&
          !_enviando &&
          !_acessoEncerrado &&
          ModalRoute.of(context)?.isCurrent == true) {
        _carregar();
      }
    });
  }

  void _mostrarErro(Object erro, String fallback) {
    setState(() {
      _erro = erro is ChatException ? erro.toString() : fallback;
      if (erro is ChatException && erro.acessoEncerrado) {
        _acessoEncerrado = true;
        _mensagens = null;
        _antesDe = null;
      }
    });
  }

  Future<void> _carregar({bool antigas = false}) async {
    if (_carregando) return;
    setState(() => _carregando = true);
    try {
      final pagina = await _chat.historico(
        widget.demanda.id,
        widget.canal,
        antesDe: antigas ? _antesDe : null,
      );
      if (!mounted) return;
      setState(() {
        _mensagens = antigas
            ? [..._mensagens!, ...pagina.mensagens]
            : pagina.mensagens;
        _antesDe = pagina.antesDe;
        _vendoHistorico = antigas;
        _acessoEncerrado = false;
        _erro = null;
      });
    } catch (erro) {
      if (mounted) _mostrarErro(erro, 'Falha ao carregar as mensagens.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _enviar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty || _enviando || _carregando || _acessoEncerrado) return;
    setState(() => _enviando = true);
    try {
      await _chat.enviar(widget.demanda.id, widget.canal, texto);
      if (!mounted) return;
      _texto.clear();
      await _carregar();
    } catch (erro) {
      if (mounted) {
        _mostrarErro(
          erro,
          'Falha ao confirmar o envio. Atualize a conversa antes de tentar novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  void dispose() {
    _atualizacao.cancel();
    _texto.dispose();
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.canal.titulo),
      actions: [
        IconButton(
          onPressed: _carregando || _enviando ? null : () => _carregar(),
          tooltip: 'Atualizar mensagens',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(widget.demanda.titulo, textAlign: TextAlign.center),
          ),
          if (_erro != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_erro!, textAlign: TextAlign.center),
            ),
          Expanded(child: _historico(context)),
          if (!_acessoEncerrado && _mensagens != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _texto,
                      readOnly: _enviando,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Mensagem',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _enviando || _carregando ? null : _enviar,
                    tooltip: 'Enviar mensagem',
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  Widget _historico(BuildContext context) {
    final mensagens = _mensagens;
    if (mensagens == null) {
      return _carregando
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink();
    }
    if (mensagens.isEmpty) {
      return const Center(child: Text('Ainda não há mensagens.'));
    }
    final cores = Theme.of(context).colorScheme;
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: mensagens.length + (_antesDe == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == mensagens.length) {
          return TextButton(
            onPressed: _carregando || _enviando
                ? null
                : () => _carregar(antigas: true),
            child: const Text('Carregar mensagens anteriores'),
          );
        }
        final mensagem = mensagens[index];
        final minha = mensagem.autorId == widget.usuario.id;
        final localizacao = MaterialLocalizations.of(context);
        final data = localizacao.formatShortDate(mensagem.criadoEm);
        final hora = localizacao.formatTimeOfDay(
          TimeOfDay.fromDateTime(mensagem.criadoEm),
        );
        return Align(
          alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
          child: Card(
            color: minha ? cores.primaryContainer : cores.surfaceContainerHigh,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${minha ? 'Você' : mensagem.autorNome} · $data $hora',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    SelectableText(mensagem.texto),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
