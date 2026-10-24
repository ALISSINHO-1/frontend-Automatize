
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'painel_screen.dart';
import 'demanda_store.dart';
import '../../../../shared/widgets/main_layout.dart';

class DemandasScreen extends StatefulWidget {
  const DemandasScreen({super.key});

  @override
  State<DemandasScreen> createState() => _DemandasScreenState();
}

class _DemandasScreenState extends State<DemandasScreen> {
  final TextEditingController _buscaController =
      TextEditingController();

  final DemandaStore _store = DemandaStore.instance;

  String _filtroStatus = 'Todos os estados';

  final List<String> _estados = [
    'Planejamento',
    'Homologação',
    'Concluído',
  ];

  @override
  void initState() {
    super.initState();
    _store.addListener(_quandoDemandasMudarem);
  }

  void _quandoDemandasMudarem() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _store.removeListener(_quandoDemandasMudarem);
    _buscaController.dispose();
    super.dispose();
  }

  // Filtra as demandas do armazenamento compartilhado.
  List<DemandaItem> get _demandasFiltradas {
    final busca = _buscaController.text.trim().toLowerCase();

    return _store.demandas.where((demanda) {
      final correspondeBusca =
          demanda.codigo.toLowerCase().contains(busca) ||
          demanda.titulo.toLowerCase().contains(busca) ||
          demanda.descricao.toLowerCase().contains(busca);

      final correspondeStatus =
          _filtroStatus == 'Todos os estados' ||
          demanda.estado == _filtroStatus;

      return correspondeBusca && correspondeStatus;
    }).toList();
  }

  Color _corStatus(String estado) {
    switch (estado) {
      case 'Planejamento':
        return const Color(0xFF6366F1);
      case 'Homologação':
        return const Color(0xFF8B5CF6);
      case 'Concluído':
        return const Color(0xFF059669);
      default:
        return Colors.blueGrey;
    }
  }

  // Cadastro em uma janela; edição em uma página própria.
  Future<void> _abrirFormulario({
    DemandaItem? demanda,
  }) async {
    if (demanda != null) {
      final resultado =
          await Navigator.of(context).push<Map<String, String>>(
        MaterialPageRoute(
          builder: (_) => _EditarDemandaScreen(
            demanda: demanda,
            estados: _estados,
          ),
        ),
      );

      if (resultado == null || !mounted) {
        return;
      }

      _store.atualizar(
        id: demanda.id,
        titulo: resultado['titulo']!,
        descricao: resultado['descricao']!,
        estado: resultado['estado']!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alterações salvas na demonstração!'),
        ),
      );

      return;
    }

    final resultado = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _FormularioDemandaDialog(
        tituloInicial: '',
        descricaoInicial: '',
        estadoInicial: 'Planejamento',
        estados: _estados,
      ),
    );

    if (resultado == null || !mounted) {
      return;
    }

    _store.adicionar(
      titulo: resultado['titulo']!,
      descricao: resultado['descricao']!,
      estado: resultado['estado']!,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demanda cadastrada na demonstração!'),
      ),
    );
  }

  // Exibe os detalhes da demanda selecionada.
  void _visualizarDemanda(DemandaItem demanda) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Detalhes da demanda'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detalhe('Código', demanda.codigo),
                _detalhe('Título', demanda.titulo),
                _detalhe(
                  'Descrição',
                  demanda.descricao.isEmpty
                      ? 'Sem descrição'
                      : demanda.descricao,
                ),
                _detalhe('Estado', demanda.estado),
                const SizedBox(height: 12),
                Text('Progresso: ${demanda.progresso}%'),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: demanda.progresso / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Widget _detalhe(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Confirma a exclusão antes de remover do armazenamento.
  Future<void> _excluirDemanda(DemandaItem demanda) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir demanda?'),
          content: Text(
            'Deseja excluir "${demanda.titulo}"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmou != true || !mounted) {
      return;
    }

    _store.remover(demanda.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Demanda removida da demonstração.',
        ),
      ),
    );
  }

  // Navegação compartilhada entre as telas.
  void _navegarParaPainel() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const PainelScreen(),
      ),
    );
  }

  // Encerra a navegação atual e retorna ao login.
  void _sair() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final demandasVisiveis = _demandasFiltradas;

    return MainLayout(
      selectedIndex: 1,
      onDestinationSelected: (index) {
        if (index == 0) {
          _navegarParaPainel();
        }
      },
      onLogout: _sair,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Minhas demandas',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Visualize e gerencie suas demandas.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _abrirFormulario(),
                      icon: const Icon(Icons.add),
                      label: const Text('Nova demanda'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1677F2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Busca e filtro.
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        controller: _buscaController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Buscar demanda...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: _filtroStatus,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Estado',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: [
                          'Todos os estados',
                          ..._estados,
                        ].map((estado) {
                          return DropdownMenuItem<String>(
                            value: estado,
                            child: Text(
                              estado,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          if (valor != null) {
                            setState(() {
                              _filtroStatus = valor;
                            });
                          }
                        },
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _buscaController.clear();
                          _filtroStatus = 'Todos os estados';
                        });
                      },
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Limpar filtros'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Tabela de demandas.
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    child: demandasVisiveis.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 48,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Nenhuma demanda encontrada.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor:
                                    WidgetStateProperty.all(
                                  const Color(0xFFF8FAFC),
                                ),
                                columnSpacing: 26,
                                horizontalMargin: 20,
                                columns: const [
                                  DataColumn(label: Text('Código')),
                                  DataColumn(label: Text('Título')),
                                  DataColumn(label: Text('Estado')),
                                  DataColumn(label: Text('Progresso')),
                                  DataColumn(label: Text('Ações')),
                                ],
                                rows: demandasVisiveis.map((demanda) {
                                  final cor = _corStatus(demanda.estado);

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          demanda.codigo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 270,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                demanda.titulo,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                demanda.descricao,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: cor.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            demanda.estado,
                                            style: TextStyle(
                                              color: cor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 150,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child:
                                                    LinearProgressIndicator(
                                                  value:
                                                      demanda.progresso /
                                                          100,
                                                  minHeight: 7,
                                                  backgroundColor:
                                                      const Color(
                                                    0xFFE2E8F0,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                '${demanda.progresso}%',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        PopupMenuButton<_AcaoDemanda>(
                                          tooltip: 'Ações',
                                          icon: const Icon(
                                            Icons.more_vert,
                                          ),
                                          onSelected: (acao) {
                                            switch (acao) {
                                              case _AcaoDemanda.visualizar:
                                                _visualizarDemanda(demanda);
                                                break;
                                              case _AcaoDemanda.editar:
                                                _abrirFormulario(
                                                  demanda: demanda,
                                                );
                                                break;
                                              case _AcaoDemanda.excluir:
                                                _excluirDemanda(demanda);
                                                break;
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(
                                              value: _AcaoDemanda.visualizar,
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.visibility_outlined,
                                                ),
                                                title: Text('Ver detalhes'),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: _AcaoDemanda.editar,
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.edit_outlined,
                                                ),
                                                title: Text('Editar'),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: _AcaoDemanda.excluir,
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.delete_outline,
                                                  color: Color(0xFFDC2626),
                                                ),
                                                title: Text('Excluir'),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  '${demandasVisiveis.length} '
                  '${demandasVisiveis.length == 1 ? 'demanda encontrada' : 'demandas encontradas'}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
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

// Página de edição.
class _EditarDemandaScreen extends StatefulWidget {
  final DemandaItem demanda;
  final List<String> estados;

  const _EditarDemandaScreen({
    required this.demanda,
    required this.estados,
  });

  @override
  State<_EditarDemandaScreen> createState() =>
      _EditarDemandaScreenState();
}

class _EditarDemandaScreenState
    extends State<_EditarDemandaScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;

  late String _estadoSelecionado;

  @override
  void initState() {
    super.initState();

    _tituloController = TextEditingController(
      text: widget.demanda.titulo,
    );
    _descricaoController = TextEditingController(
      text: widget.demanda.descricao,
    );
    _estadoSelecionado = widget.demanda.estado;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _salvarAlteracoes() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop<Map<String, String>>({
      'titulo': _tituloController.text.trim(),
      'descricao': _descricaoController.text.trim(),
      'estado': _estadoSelecionado,
    });
  }

  void _navegarParaPainel() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const PainelScreen(),
      ),
    );
  }

  void _sair() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final demanda = widget.demanda;

    return MainLayout(
      selectedIndex: 1,
      onDestinationSelected: (index) {
        if (index == 0) {
          _navegarParaPainel();
        }
      },
      onLogout: _sair,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar para demandas'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editar demanda',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Altere os campos permitidos e revise as informações.',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: Text(
                            demanda.codigo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _tituloController,
                                maxLength: 255,
                                decoration: const InputDecoration(
                                  labelText: 'Título *',
                                  border: OutlineInputBorder(),
                                  counterText: '',
                                ),
                                validator: (valor) {
                                  if (valor == null ||
                                      valor.trim().length < 3) {
                                    return 'Informe pelo menos 3 caracteres.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 22),
                              TextFormField(
                                controller: _descricaoController,
                                minLines: 3,
                                maxLines: 5,
                                maxLength: 1000,
                                decoration: const InputDecoration(
                                  labelText: 'Descrição',
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                initialValue: _estadoSelecionado,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Estado',
                                  border: OutlineInputBorder(),
                                ),
                                items: widget.estados.map((estado) {
                                  return DropdownMenuItem<String>(
                                    value: estado,
                                    child: Text(estado),
                                  );
                                }).toList(),
                                onChanged: (valor) {
                                  if (valor != null) {
                                    setState(() {
                                      _estadoSelecionado = valor;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF64748B),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Revise os dados antes de salvar. Nesta demonstração, '
                                        'as alterações são mantidas apenas enquanto o aplicativo estiver aberto.',
                                        style: TextStyle(
                                          color: Color(0xFF475569),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 16,
                                      ),
                                    ),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _salvarAlteracoes,
                                    icon: const Icon(Icons.save_outlined),
                                    label: const Text('Salvar alterações'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1677F2),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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

// Formulário de cadastro.
class _FormularioDemandaDialog extends StatefulWidget {
  final String tituloInicial;
  final String descricaoInicial;
  final String estadoInicial;
  final List<String> estados;

  const _FormularioDemandaDialog({
    required this.tituloInicial,
    required this.descricaoInicial,
    required this.estadoInicial,
    required this.estados,
  });

  @override
  State<_FormularioDemandaDialog> createState() =>
      _FormularioDemandaDialogState();
}

class _FormularioDemandaDialogState
    extends State<_FormularioDemandaDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;

  late String _estadoSelecionado;

  @override
  void initState() {
    super.initState();

    _tituloController = TextEditingController(
      text: widget.tituloInicial,
    );
    _descricaoController = TextEditingController(
      text: widget.descricaoInicial,
    );
    _estadoSelecionado = widget.estadoInicial;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova demanda'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _tituloController,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (valor == null ||
                        valor.trim().length < 3) {
                      return 'Informe pelo menos 3 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descricaoController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _estadoSelecionado,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.estados.map((estado) {
                    return DropdownMenuItem<String>(
                      value: estado,
                      child: Text(estado),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    if (valor != null) {
                      setState(() {
                        _estadoSelecionado = valor;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) {
              return;
            }

            Navigator.of(context).pop<Map<String, String>>({
              'titulo': _tituloController.text.trim(),
              'descricao': _descricaoController.text.trim(),
              'estado': _estadoSelecionado,
            });
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Cadastrar'),
        ),
      ],
    );
  }
}

enum _AcaoDemanda {
  visualizar,
  editar,
  excluir,
}
