import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../../shared/widgets/main_layout.dart';
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
  final _chat = ChatService();
  bool _assumindo = false;
  PedidoModel? _demandaSelecionada;
  ChatCanal? _canalSelecionado;
  late var _dados = _carregar();

  Future<
    ({
      UsuarioAtualModel? usuario,
      List<PedidoModel> demandas,
      List<DemandaNaFila>? fila,
    })
  >
  _carregar() async {
    final usuario = await UsuarioAtualStore.instance.carregar();
    final demandas = usuario == null
        ? <PedidoModel>[]
        : await _demandas.buscarDemandas();
    List<DemandaNaFila>? fila = const [];
    if (usuario?.perfil == 'TECNICO') {
      try {
        fila = await _chat.buscarFila();
      } catch (_) {
        fila = null;
      }
    }
    return (usuario: usuario, demandas: demandas.reversed.toList(), fila: fila);
  }

  void _atualizar() => setState(() => _dados = _carregar());

  Future<void> _assumir(DemandaNaFila demanda) async {
    if (_assumindo) return;
    setState(() => _assumindo = true);
    String mensagem;
    try {
      final assumiu = await _chat.assumir(demanda.id);
      mensagem = assumiu
          ? 'Demanda assumida. O chat está disponível em Minhas conversas.'
          : 'A demanda não está mais disponível na fila.';
    } catch (_) {
      mensagem =
          'Não foi possível confirmar a atribuição. A lista será atualizada.';
    }
    if (!mounted) return;
    setState(() {
      _assumindo = false;
      _dados = _carregar();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  void dispose() {
    _chat.dispose();
    _demandas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MainLayout(
    selectedIndex: 4,
    onDestinationSelected: (index) {
      if (index == 0) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.painel);
      }
      if (index == 1) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.demandas);
      }
    },
    child: Scaffold(
      backgroundColor: AutomatizeColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AutomatizeColors.primary.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AutomatizeColors.border),
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: AutomatizeColors.cyan,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conversas',
                          style: TextStyle(
                            color: AutomatizeColors.text,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Acompanhe as conversas vinculadas às demandas.',
                          style: TextStyle(color: AutomatizeColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: _assumindo ? null : _atualizar,
                    tooltip: 'Atualizar conversas',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Expanded(child: _conteudo()),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _conteudo() => FutureBuilder(
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
      if (usuario == null || canais.isEmpty) {
        return const Center(child: Text('Nenhuma conversa disponível.'));
      }
      final tecnico = usuario.perfil == 'TECNICO';
      final fila = dados.fila;
      if (!tecnico && dados.demandas.isEmpty) {
        return const Center(child: Text('Nenhuma conversa disponível.'));
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 760;
          final lista = _listaConversas(
            usuario: usuario,
            canais: canais,
            demandas: dados.demandas,
            tecnico: tecnico,
            fila: fila,
            compacto: compacto,
          );
          if (compacto) return lista;
          return Container(
            decoration: BoxDecoration(
              color: AutomatizeColors.panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AutomatizeColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                SizedBox(width: 340, child: lista),
                const VerticalDivider(width: 1),
                Expanded(
                  child:
                      _demandaSelecionada == null || _canalSelecionado == null
                      ? const _ChatEmptyState()
                      : _ConversaPage(
                          key: ValueKey(
                            '${_demandaSelecionada!.id}-${_canalSelecionado!.name}',
                          ),
                          demanda: _demandaSelecionada!,
                          canal: _canalSelecionado!,
                          usuario: usuario,
                          embedded: true,
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  Widget _listaConversas({
    required UsuarioAtualModel usuario,
    required List<ChatCanal> canais,
    required List<PedidoModel> demandas,
    required bool tecnico,
    required List<DemandaNaFila>? fila,
    required bool compacto,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: compacto ? AutomatizeColors.panel : AutomatizeColors.sidebar,
        borderRadius: compacto ? BorderRadius.circular(18) : BorderRadius.zero,
        border: compacto ? Border.all(color: AutomatizeColors.border) : null,
      ),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (tecnico) ...[
            const _ChatSectionTitle(
              title: 'Fila de atendimento',
              subtitle: 'Demandas disponíveis para assumir',
            ),
            if (fila == null)
              _ChatNotice(
                text: 'Não foi possível carregar a fila.',
                action: TextButton(
                  onPressed: _atualizar,
                  child: const Text('Tentar novamente'),
                ),
              )
            else if (fila.isEmpty)
              const _ChatNotice(text: 'Nenhuma demanda disponível na fila.')
            else
              for (final demanda in fila)
                Card(
                  color: AutomatizeColors.panelLight,
                  child: ListTile(
                    dense: true,
                    title: Text(
                      demanda.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(demanda.codigo),
                    trailing: IconButton.filledTonal(
                      onPressed: _assumindo ? null : () => _assumir(demanda),
                      tooltip: 'Assumir demanda',
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                    ),
                  ),
                ),
            const SizedBox(height: 18),
          ],
          const _ChatSectionTitle(
            title: 'Minhas conversas',
            subtitle: 'Canais vinculados às demandas',
          ),
          if (demandas.isEmpty)
            const _ChatNotice(text: 'Nenhuma conversa disponível.'),
          for (final demanda in demandas)
            for (final canal in canais)
              _conversaItem(
                demanda: demanda,
                canal: canal,
                usuario: usuario,
                compacto: compacto,
              ),
        ],
      ),
    );
  }

  Widget _conversaItem({
    required PedidoModel demanda,
    required ChatCanal canal,
    required UsuarioAtualModel usuario,
    required bool compacto,
  }) {
    final temTecnico = demanda.responsavelId != null;
    final selecionada =
        _demandaSelecionada?.id == demanda.id && _canalSelecionado == canal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selecionada
            ? AutomatizeColors.primary.withValues(alpha: .2)
            : AutomatizeColors.panel,
        borderRadius: BorderRadius.circular(13),
        child: ListTile(
          enabled: temTecnico,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: BorderSide(
              color: selecionada
                  ? AutomatizeColors.primary
                  : AutomatizeColors.border,
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: AutomatizeColors.primary.withValues(alpha: .15),
            child: Icon(
              canal == ChatCanal.cliente
                  ? Icons.support_agent_rounded
                  : Icons.admin_panel_settings_outlined,
              color: AutomatizeColors.cyan,
              size: 20,
            ),
          ),
          title: Text(
            demanda.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            temTecnico
                ? '${demanda.codigoIdentificador ?? demanda.id} · ${canal.titulo}'
                : 'Aguardando técnico responsável',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: !temTecnico
              ? null
              : () {
                  if (compacto) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _ConversaPage(
                          demanda: demanda,
                          canal: canal,
                          usuario: usuario,
                        ),
                      ),
                    );
                  } else {
                    setState(() {
                      _demandaSelecionada = demanda;
                      _canalSelecionado = canal;
                    });
                  }
                },
        ),
      ),
    );
  }
}

class _ChatSectionTitle extends StatelessWidget {
  const _ChatSectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: AutomatizeColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _ChatNotice extends StatelessWidget {
  const _ChatNotice({required this.text, this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AutomatizeColors.background.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AutomatizeColors.border),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: AutomatizeColors.muted, size: 18),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
        ?action,
      ],
    ),
  );
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mark_chat_unread_outlined,
          size: 54,
          color: AutomatizeColors.muted,
        ),
        SizedBox(height: 16),
        Text(
          'Selecione uma conversa',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 6),
        Text(
          'As mensagens aparecerão aqui.',
          style: TextStyle(color: AutomatizeColors.muted),
        ),
      ],
    ),
  );
}

class _ConversaPage extends StatefulWidget {
  const _ConversaPage({
    super.key,
    required this.demanda,
    required this.canal,
    required this.usuario,
    this.embedded = false,
  });

  final PedidoModel demanda;
  final ChatCanal canal;
  final UsuarioAtualModel usuario;
  final bool embedded;

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
  Widget build(BuildContext context) {
    final conteudo = SafeArea(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AutomatizeColors.background),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: AutomatizeColors.panel,
                border: Border(
                  bottom: BorderSide(color: AutomatizeColors.border),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AutomatizeColors.primary.withValues(
                      alpha: .16,
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: AutomatizeColors.cyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.demanda.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.demanda.codigoIdentificador ?? widget.demanda.id} · ${widget.canal.titulo}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AutomatizeColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _carregando || _enviando
                        ? null
                        : () => _carregar(),
                    tooltip: 'Atualizar mensagens',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            if (_erro != null)
              Container(
                width: double.infinity,
                color: AutomatizeColors.danger.withValues(alpha: .12),
                padding: const EdgeInsets.all(10),
                child: Text(
                  _erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFFA0AA)),
                ),
              ),
            Expanded(child: _historico(context)),
            if (!_acessoEncerrado && _mensagens != null)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: AutomatizeColors.panel,
                  border: Border(
                    top: BorderSide(color: AutomatizeColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _texto,
                        readOnly: _enviando,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 2000,
                        decoration: InputDecoration(
                          hintText: 'Escreva uma mensagem...',
                          counterText: '',
                          filled: true,
                          fillColor: AutomatizeColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AutomatizeColors.border,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _enviar(),
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
    if (widget.embedded) return conteudo;
    return Scaffold(
      backgroundColor: AutomatizeColors.background,
      appBar: AppBar(title: const Text('Conversa')),
      body: conteudo,
    );
  }

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
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
          child: Container(
            margin: const EdgeInsets.only(bottom: 9),
            decoration: BoxDecoration(
              color: minha
                  ? AutomatizeColors.primary.withValues(alpha: .28)
                  : AutomatizeColors.panelLight,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(minha ? 14 : 3),
                bottomRight: Radius.circular(minha ? 3 : 14),
              ),
              border: Border.all(
                color: minha
                    ? AutomatizeColors.primary
                    : AutomatizeColors.border,
              ),
            ),
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
