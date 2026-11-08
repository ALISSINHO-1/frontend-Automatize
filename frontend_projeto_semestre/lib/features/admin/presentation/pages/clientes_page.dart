import 'package:flutter/material.dart';

import '../../../../shared/widgets/main_layout.dart';
import '../../../demands/data/models/pedido_model.dart';
import '../../../demands/data/services/demand_service.dart';
import '../../../demands/presentation/pages/demand_tasks_page.dart';
import '../../../home/presentation/pages/demanda_store.dart';
import '../../../home/presentation/pages/demandas_screen.dart';
import '../../../home/presentation/pages/painel_screen.dart';
import '../../../home/presentation/pages/visualizacoes_demandas.dart';
import '../../data/models/usuario_atual_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/admin_demand_service.dart';
import '../../data/services/usuario_atual_store.dart';
import '../widgets/admin_user_dialogs.dart';

enum _Modo { grade, lista, quadro }

enum _Filtro { todos, ativos, inativos }

const _fundo = Color(0xFF0B1122);
const _painel = Color(0xFF141E32);
const _borda = Color(0xFF26334D);
const _azul = Color(0xFF3BA5FF);
const _cores = [_azul, Color(0xFFA38BFF), Color(0xFFFFC751), Color(0xFF45D680)];
const _estados = {
  'PLANEAMENTO': 'Planejamento',
  'EXECUCAO': 'Execução',
  'HOMOLOGACAO': 'Homologação',
  'CONCLUIDO': 'Concluído',
};

typedef _Tarefa = ({String id, String descricao, bool concluida});

class _Cliente {
  const _Cliente(this.conta, this.demandas, this.tarefas);
  final UsuarioModel conta;
  final List<PedidoModel> demandas;
  final List<_Tarefa> tarefas;

  int get abertas => demandas.where((d) => d.status != 'CONCLUIDO').length;
  int get concluidas => tarefas.where((t) => t.concluida).length;
  double? get progresso => tarefas.isEmpty ? null : concluidas / tarefas.length;

  bool corresponde(String termo) =>
      conta.nome.toLowerCase().contains(termo) ||
      demandas.any(
        (d) =>
            d.titulo.toLowerCase().contains(termo) ||
            (d.codigoIdentificador ?? '').toLowerCase().contains(termo),
      ) ||
      tarefas.any((t) => t.descricao.toLowerCase().contains(termo));
}

typedef _Painel = ({
  UsuarioAtualModel usuario,
  List<_Cliente> clientes,
  Map<String, String> tecnicos,
});

class ClientesPage extends StatefulWidget {
  const ClientesPage({
    super.key,
    this.adminService,
    this.demandService,
    this.carregarUsuario,
  });

  final AdminDemandService? adminService;
  final DemandService? demandService;
  final Future<UsuarioAtualModel?> Function()? carregarUsuario;

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  late final _admin = widget.adminService ?? AdminDemandService();
  late final _api = widget.demandService ?? DemandService();
  late var _dados = _carregar();
  var _modo = _Modo.grade;
  var _filtro = _Filtro.todos;
  var _busca = '';
  String? _clienteQuadro;
  var _coluna = 0;
  var _crescente = true;
  var _salvando = false;

  Future<_Painel> _carregar() async {
    final usuario =
        await (widget.carregarUsuario ?? UsuarioAtualStore.instance.carregar)();
    if (usuario == null || (!usuario.isAdmin && usuario.perfil != 'TECNICO')) {
      throw const DemandServiceException(
        'Área disponível para administradores e técnicos.',
      );
    }
    if (!mounted) throw const DemandServiceException('Consulta encerrada.');
    final (contas, demandas, tecnicos) = await (
      usuario.isAdmin
          ? _admin.listarUsuarios(perfil: 'CLIENTE')
          : _admin.listarClientesVinculados(),
      _api.buscarDemandas(),
      usuario.isAdmin
          ? _admin.listarUsuarios(perfil: 'TECNICO')
          : Future.value(<UsuarioModel>[]),
    ).wait;
    final grupos = {for (final conta in contas) conta.id: <PedidoModel>[]};
    final tarefas = {for (final conta in contas) conta.id: <_Tarefa>[]};
    final visiveis = demandas
        .where((d) => grupos.containsKey(d.clienteId))
        .toList();
    // Limita a concorrência ao usar as rotas de etapas por demanda.
    for (var i = 0; i < visiveis.length && mounted; i += 8) {
      await Future.wait(
        visiveis.skip(i).take(8).map((demanda) async {
          grupos[demanda.clienteId]!.add(demanda);
          tarefas[demanda.clienteId]!.addAll(
            await _api.listarTarefas(demanda.id),
          );
        }),
      );
    }
    return (
      usuario: usuario,
      clientes: [
        for (final conta in contas)
          _Cliente(conta, grupos[conta.id]!, tarefas[conta.id]!),
      ],
      tecnicos: {
        for (final tecnico in tecnicos) tecnico.id: tecnico.nome,
        usuario.id: usuario.nome,
      },
    );
  }

  @override
  void dispose() {
    _buscaController.dispose();
    if (widget.adminService == null) _admin.dispose();
    if (widget.demandService == null) _api.dispose();
    super.dispose();
  }

  void _atualizar() => setState(() => _dados = _carregar());

  Future<void> _salvar(Future<void> Function() acao, String sucesso) async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      await acao();
      if (!mounted) return;
      _atualizar();
      _mensagem(sucesso);
    } catch (erro) {
      if (mounted) _mensagem('$erro');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mensagem(String texto) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _novoCliente() async {
    final dados = await UsuarioFormDialog.show(context, perfilFixo: 'CLIENTE');
    if (!mounted || dados == null) return;
    await _salvar(() async {
      await _admin.criarUsuario(
        nome: dados.nome,
        email: dados.email,
        senha: dados.senha,
        perfil: 'CLIENTE',
      );
    }, 'Cliente cadastrado.');
  }

  Future<void> _tarefas(PedidoModel demanda, UsuarioAtualModel usuario) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DemandTasksPage(
          demandaId: demanda.id,
          titulo: demanda.titulo,
          status: demanda.status,
          usuario: usuario,
          service: _api,
        ),
      ),
    );
    if (mounted) _atualizar();
  }

  Future<void> _detalhes(_Cliente cliente, UsuarioAtualModel usuario) async {
    final demanda = await showDialog<PedidoModel>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        backgroundColor: _painel,
        title: Text(cliente.conta.nome),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cliente.conta.email.isNotEmpty) Text(cliente.conta.email),
              const SizedBox(height: 12),
              Text(
                '${cliente.abertas} demandas abertas · ${cliente.tarefas.length} tarefas',
              ),
              const SizedBox(height: 12),
              if (cliente.demandas.isEmpty)
                const Text('Nenhuma demanda cadastrada.'),
              for (final demanda in cliente.demandas)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(demanda.titulo),
                  subtitle: Text(_estados[demanda.status] ?? demanda.status),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, demanda),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
    if (mounted && demanda != null) await _tarefas(demanda, usuario);
  }

  List<_Cliente> _filtrar(List<_Cliente> clientes) {
    final visiveis = clientes
        .where(
          (cliente) => switch (_filtro) {
            _Filtro.todos => true,
            _Filtro.ativos => cliente.conta.ativo,
            _Filtro.inativos => !cliente.conta.ativo,
          },
        )
        .where((cliente) => cliente.corresponde(_busca.trim().toLowerCase()))
        .toList();
    int comparar(_Cliente a, _Cliente b) => switch (_coluna) {
      1 => (a.conta.ativo ? 1 : 0).compareTo(b.conta.ativo ? 1 : 0),
      2 => a.demandas.length.compareTo(b.demandas.length),
      3 => a.tarefas.length.compareTo(b.tarefas.length),
      4 => (a.progresso ?? -1).compareTo(b.progresso ?? -1),
      _ => a.conta.nome.toLowerCase().compareTo(b.conta.nome.toLowerCase()),
    };
    return visiveis
      ..sort((a, b) => _crescente ? comparar(a, b) : comparar(b, a));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: MainLayout(
      selectedIndex: MainLayout.indiceClientes,
      onDestinationSelected: (index) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) =>
                index == 0 ? const PainelScreen() : const DemandasScreen(),
          ),
        );
      },
      child: ColoredBox(
        color: _fundo,
        child: SafeArea(
          child: FutureBuilder<_Painel>(
            future: _dados,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Não foi possível carregar o painel de clientes.',
                        ),
                        Text('${snapshot.error}', textAlign: TextAlign.center),
                        TextButton(
                          onPressed: _atualizar,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return _conteudo(snapshot.data!);
            },
          ),
        ),
      ),
    ),
  );

  Widget _conteudo(_Painel dados) {
    final clientes = dados.clientes;
    final ativos = clientes.where((c) => c.conta.ativo).length;
    final visiveis = _filtrar(clientes);
    final concluidas = clientes.fold(0, (total, c) => total + c.concluidas);
    return LayoutBuilder(
      builder: (context, area) {
        final compacto = area.maxWidth < 560;
        final padding = compacto ? 14.0 : 26.0;
        return ListView(
          padding: EdgeInsets.all(padding),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: compacto ? area.maxWidth - 2 * padding : 360,
                  child: TextField(
                    key: const Key('busca-clientes'),
                    onChanged: (texto) => setState(() => _busca = texto),
                    controller: _buscaController,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Buscar clientes, demandas ou tarefas…',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.account_circle_outlined,
                    color: _azul,
                  ),
                  label: Text(
                    '${dados.usuario.nome} · ${UsuarioModel.rotuloPerfil(dados.usuario.perfil)}',
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: _borda),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5, right: 12),
                  child: Icon(Icons.people_outline, size: 31, color: _azul),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clientes',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Gerencie seus clientes e acompanhe as demandas de cada um.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _grade(
              [
                _indicador(
                  Icons.people_outline,
                  'Clientes ativos',
                  ativos,
                  _cores[0],
                ),
                _indicador(
                  Icons.layers_outlined,
                  'Demandas abertas',
                  clientes.fold(0, (total, c) => total + c.abertas),
                  _cores[1],
                ),
                _indicador(
                  Icons.pending_actions,
                  'Tarefas em andamento',
                  clientes.fold(0, (total, c) => total + c.tarefas.length) -
                      concluidas,
                  _cores[2],
                ),
                _indicador(
                  Icons.check_circle_outline,
                  'Tarefas concluídas',
                  concluidas,
                  _cores[3],
                ),
              ],
              larguraMinima: 176,
              maximo: 4,
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final filtro in _Filtro.values)
                  ChoiceChip(
                    label: Text(switch (filtro) {
                      _Filtro.todos => 'Todos (${clientes.length})',
                      _Filtro.ativos => 'Ativos ($ativos)',
                      _Filtro.inativos =>
                        'Inativos (${clientes.length - ativos})',
                    }),
                    selected: _filtro == filtro,
                    onSelected: (_) => setState(() => _filtro = filtro),
                  ),
                for (final (modo, icone, nome) in const [
                  (_Modo.grade, Icons.grid_view, 'Grade'),
                  (_Modo.lista, Icons.view_list_outlined, 'Lista'),
                  (_Modo.quadro, Icons.view_kanban_outlined, 'Quadro'),
                ])
                  IconButton(
                    tooltip: nome,
                    isSelected: _modo == modo,
                    selectedIcon: Icon(icone, color: _azul),
                    icon: Icon(icone),
                    onPressed: () => setState(() => _modo = modo),
                  ),
                IconButton(
                  tooltip: 'Atualizar clientes',
                  icon: const Icon(Icons.refresh),
                  onPressed: _salvando ? null : _atualizar,
                ),
                if (dados.usuario.isAdmin)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0964F3),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _salvando ? null : _novoCliente,
                    icon: const Icon(Icons.add),
                    label: const Text('Novo Cliente'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_salvando) const LinearProgressIndicator(),
            if (visiveis.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: Text('Nenhum cliente encontrado.')),
              )
            else
              switch (_modo) {
                _Modo.grade => _grade(
                  [
                    for (final cliente in visiveis)
                      _cartao(cliente, dados.usuario),
                  ],
                  larguraMinima: 285,
                  maximo: 2,
                ),
                _Modo.lista => _lista(visiveis, dados.usuario),
                _Modo.quadro => _quadro(visiveis, dados),
              },
          ],
        );
      },
    );
  }

  final _buscaController = TextEditingController();

  Widget _grade(
    List<Widget> itens, {
    required double larguraMinima,
    required int maximo,
  }) => LayoutBuilder(
    builder: (context, medidas) {
      const gap = 12.0;
      final colunas = ((medidas.maxWidth + gap) / (larguraMinima + gap))
          .floor()
          .clamp(1, maximo);
      final largura = (medidas.maxWidth - (colunas - 1) * gap) / colunas;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in itens) SizedBox(width: largura, child: item),
        ],
      );
    },
  );

  Widget _superficie(Widget child) => Card(
    color: _painel,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: _borda),
    ),
    child: child,
  );

  Widget _icone(IconData icone, Color cor) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: cor.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icone, color: cor, size: 22),
  );

  Widget _indicador(IconData icone, String rotulo, int valor, Color cor) =>
      _superficie(
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _icone(icone, cor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$valor',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(rotulo, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _status(_Cliente cliente) {
    final ativo = cliente.conta.ativo;
    final cor = ativo ? _cores[3] : AutomatizeColors.muted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cor.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          ativo ? 'Ativo' : 'Inativo',
          style: TextStyle(color: cor, fontSize: 12),
        ),
      ),
    );
  }

  Widget _progresso(_Cliente cliente, Color cor) {
    final valor = cliente.progresso;
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: valor ?? 0,
            color: cor,
            backgroundColor: _borda,
            minHeight: 7,
            borderRadius: BorderRadius.circular(6),
            semanticsLabel: 'Progresso das tarefas',
          ),
        ),
        const SizedBox(width: 10),
        Text(valor == null ? '—' : '${(valor * 100).round()}%'),
      ],
    );
  }

  Widget _cartao(_Cliente cliente, UsuarioAtualModel usuario) {
    final cor =
        _cores[cliente.conta.id.codeUnits.fold(0, (soma, c) => soma + c) %
            _cores.length];
    return _superficie(
      InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _detalhes(cliente, usuario),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _icone(Icons.business_outlined, cor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          cliente.conta.nome,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _status(cliente),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              if (cliente.conta.email.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    cliente.conta.email,
                    style: const TextStyle(color: AutomatizeColors.muted),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  Text('${cliente.demandas.length} demandas'),
                  Text('${cliente.tarefas.length} tarefas'),
                ],
              ),
              const SizedBox(height: 10),
              _progresso(cliente, cor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lista(List<_Cliente> clientes, UsuarioAtualModel usuario) =>
      _superficie(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortColumnIndex: _coluna,
            sortAscending: _crescente,
            headingRowColor: const WidgetStatePropertyAll(Color(0xFF19263C)),
            columns: [
              for (final titulo in [
                'Cliente',
                'Status',
                'Demandas',
                'Tarefas',
                'Progresso',
              ])
                DataColumn(
                  label: Text(titulo),
                  onSort: (coluna, crescente) => setState(() {
                    _coluna = coluna;
                    _crescente = crescente;
                  }),
                ),
            ],
            rows: [
              for (final cliente in clientes)
                DataRow(
                  cells: [
                    DataCell(
                      Text(cliente.conta.nome),
                      onTap: () => _detalhes(cliente, usuario),
                    ),
                    DataCell(_status(cliente)),
                    DataCell(Text('${cliente.demandas.length}')),
                    DataCell(Text('${cliente.tarefas.length}')),
                    DataCell(
                      SizedBox(width: 125, child: _progresso(cliente, _azul)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );

  Widget _quadro(List<_Cliente> clientes, _Painel dados) {
    final selecionado = clientes.firstWhere(
      (cliente) => cliente.conta.id == _clienteQuadro,
      orElse: () => clientes.first,
    );
    final demandas = {
      for (final demanda in selecionado.demandas) demanda.id: demanda,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demandas por cliente',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          isExpanded: true,
          value: selecionado.conta.id,
          items: [
            for (final cliente in clientes)
              DropdownMenuItem(
                value: cliente.conta.id,
                child: Text(
                  cliente.conta.nome,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (clienteId) => setState(() => _clienteQuadro = clienteId),
        ),
        const SizedBox(height: 8),
        if (demandas.isEmpty) const Text('Nenhuma demanda para este cliente.'),
        SizedBox(
          height: 390,
          child: QuadroDemandas(
            demandas: demandas.values.map(DemandaItem.fromPedido).toList(),
            estados: _estados.values.toList(),
            rotuloEstado: (estado) => _estados[estado] ?? estado,
            corEstado: (estado) => switch (estado) {
              'Planejamento' => _cores[0],
              'Execução' => _cores[2],
              'Homologação' => _cores[1],
              _ => _cores[3],
            },
            abrir: (demanda) => _tarefas(demandas[demanda.id]!, dados.usuario),
            nomeResponsavel: (id) => id == null
                ? 'Sem responsável'
                : dados.tecnicos[id] ?? 'Técnico atribuído',
            tecnicoId: dados.usuario.perfil == 'TECNICO'
                ? dados.usuario.id
                : null,
            mover: _salvando
                ? null
                : (demanda, origem, destino) => _salvar(
                    () => _api.moverNoQuadro(demanda.id, origem, destino),
                    'Demanda movida para ${_estados[destino]}.',
                  ),
          ),
        ),
      ],
    );
  }
}
