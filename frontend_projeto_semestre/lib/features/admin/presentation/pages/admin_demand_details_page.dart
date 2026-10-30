import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/main_layout.dart';
import '../../../demands/data/models/pedido_model.dart';
import '../../data/models/anexo_model.dart';
import '../../data/services/admin_demand_service.dart';
import '../admin_style.dart';
import '../widgets/admin_demand_dialogs.dart';
import '../widgets/demand_audit_panel.dart';

/// Detalhes da demanda com as ações do ADMIN (SCRUM-77/79) e a auditoria.
///
/// Aprovar/rejeitar a homologação não aparece aqui: no backend isso é
/// exclusivo do cliente da demanda; o admin só acompanha (SCRUM-78).
class AdminDemandDetailsPage extends StatefulWidget {
  const AdminDemandDetailsPage({
    super.key,
    required this.pedido,
    this.adminService,
    this.selecionarArquivo,
  });

  final PedidoModel pedido;
  final AdminDemandService? adminService;

  /// Substituível nos testes; por padrão abre o seletor do navegador.
  final Future<({String nome, List<int> bytes})?> Function()? selecionarArquivo;

  @override
  State<AdminDemandDetailsPage> createState() => _AdminDemandDetailsPageState();
}

class _AdminDemandDetailsPageState extends State<AdminDemandDetailsPage> {
  late final AdminDemandService _admin =
      widget.adminService ?? AdminDemandService();
  late PedidoModel _pedido = widget.pedido;
  bool _ocupado = false;
  // Trocar a key recria o painel e refaz o GET da auditoria após cada ação.
  int _versaoAuditoria = 0;

  String get _estado => AdminStyle.normalizar(_pedido.status);
  bool get _concluida => _estado == 'CONCLUIDO';

  @override
  void dispose() {
    if (widget.adminService == null) _admin.dispose();
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    setState(() => _ocupado = true);
    try {
      await acao();
      final atualizado = await _admin.buscarDemanda(_pedido.id);
      if (!mounted) return;
      setState(() {
        _pedido = atualizado;
        _versaoAuditoria++;
      });
      _mensagem(sucesso);
    } catch (erro) {
      if (mounted) _mensagem('$erro');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _mensagem(String texto) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _editar() async {
    final dados = await DemandFormDialog.show(
      context,
      tituloInicial: _pedido.titulo,
      descricaoInicial: _pedido.descricao,
    );
    if (dados == null || !mounted) return;
    await _executar(
      () => _admin.editarDemanda(
        _pedido.id,
        titulo: dados.titulo,
        descricao: dados.descricao,
      ),
      'Demanda atualizada.',
    );
  }

  Future<void> _atribuir() async {
    final responsavel = await AssignTechnicianDialog.show(
      context,
      responsavelAtual: _pedido.responsavelId,
    );
    if (responsavel == null || !mounted) return;
    await _executar(
      () => _admin.atribuirResponsavel(_pedido.id, responsavel),
      'Técnico atribuído.',
    );
  }

  Future<({String nome, List<int> bytes})?> _abrirSeletor() async {
    final arquivos = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: AnexoModel.extensoesPermitidas.toList(),
    );
    if (arquivos.isEmpty) return null;
    final arquivo = arquivos.first;
    return (nome: arquivo.name, bytes: await arquivo.readAsBytes());
  }

  Future<void> _enviarEvidencia() async {
    final arquivo = await (widget.selecionarArquivo ?? _abrirSeletor)();
    if (arquivo == null || !mounted) return;
    await _executar(
      () => _admin.enviarEvidencia(
        _pedido.id,
        nomeArquivo: arquivo.nome,
        bytes: arquivo.bytes,
      ),
      'Evidência "${arquivo.nome}" enviada.',
    );
  }

  Future<void> _excluir() async {
    if (!await confirmarExclusaoDemanda(context, _pedido.titulo)) return;
    setState(() => _ocupado = true);
    try {
      await _admin.excluirDemanda(_pedido.id);
      if (!mounted) return;
      _mensagem('Demanda excluída.');
      Navigator.of(context).pop();
    } catch (erro) {
      if (!mounted) return;
      setState(() => _ocupado = false);
      _mensagem('$erro');
    }
  }

  @override
  Widget build(BuildContext context) {
    final progresso = _pedido.percentualProgresso.clamp(0, 100).toDouble();
    return Scaffold(
      backgroundColor: AdminStyle.fundo,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AutomatizeColors.muted,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Painel administrativo'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _pedido.codigoIdentificador ?? 'DEMANDA',
                  style: const TextStyle(
                    color: AdminStyle.destaqueClaro,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(_pedido.titulo, style: AdminStyle.titulo),
                    EstadoChip(_pedido.status),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: AdminStyle.caixa(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Descrição', style: AdminStyle.tituloCard),
                      const SizedBox(height: 6),
                      Text(
                        _pedido.descricao.isEmpty
                            ? 'Sem descrição informada.'
                            : _pedido.descricao,
                        style: AdminStyle.subtitulo,
                      ),
                      const Divider(height: 36, color: AdminStyle.cardBorda),
                      Wrap(
                        spacing: 24,
                        runSpacing: 18,
                        children: [
                          _Info(
                            Icons.engineering_rounded,
                            'Técnico responsável',
                            _pedido.responsavelId ?? 'Não atribuído',
                          ),
                          _Info(
                            Icons.person_rounded,
                            'Cliente',
                            _pedido.clienteId,
                          ),
                          _Info(
                            Icons.event_rounded,
                            'Criada em',
                            AdminStyle.data(_pedido.createdAt),
                          ),
                          _Info(
                            Icons.update_rounded,
                            'Atualizada em',
                            AdminStyle.data(_pedido.updatedAt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Progresso',
                              style: TextStyle(
                                color: AutomatizeColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${progresso.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AutomatizeColors.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progresso / 100,
                          minHeight: 8,
                          color: AdminStyle.destaque,
                          backgroundColor: AdminStyle.cardBorda,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _acoes(),
                const SizedBox(height: 20),
                DemandAuditPanel(
                  key: ValueKey(_versaoAuditoria),
                  carregar: () => _admin.listarAuditoria(_pedido.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _acoes() {
    final estiloBotao = OutlinedButton.styleFrom(
      foregroundColor: AutomatizeColors.text,
      side: const BorderSide(color: AdminStyle.cardBorda),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AdminStyle.caixa(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ações administrativas', style: AdminStyle.tituloCard),
          const SizedBox(height: 14),
          // Demanda concluída é imutável no backend (409); evita botões que só falhariam.
          if (_concluida)
            const Text(
              'Demanda concluída: não aceita mais alterações.',
              style: AdminStyle.subtitulo,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  style: estiloBotao,
                  onPressed: _ocupado ? null : _editar,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Editar'),
                ),
                OutlinedButton.icon(
                  style: estiloBotao,
                  onPressed: _ocupado ? null : _atribuir,
                  icon: const Icon(Icons.engineering_rounded, size: 18),
                  label: Text(
                    _pedido.responsavelId == null
                        ? 'Atribuir técnico'
                        : 'Trocar técnico',
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminStyle.destaque,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _ocupado ? null : _enviarEvidencia,
                  icon: const Icon(Icons.attach_file_rounded, size: 18),
                  label: const Text('Enviar evidência'),
                ),
                OutlinedButton.icon(
                  style: estiloBotao.copyWith(
                    foregroundColor: const WidgetStatePropertyAll(
                      AutomatizeColors.danger,
                    ),
                  ),
                  onPressed: _ocupado ? null : _excluir,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Excluir'),
                ),
              ],
            ),
          if (_estado == 'HOMOLOGACAO') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  size: 18,
                  color: AdminStyle.corEstado(_estado),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Em homologação: aguardando o aceite ou a rejeição do cliente.',
                    style: AdminStyle.subtitulo,
                  ),
                ),
              ],
            ),
          ],
          if (_ocupado) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(color: AdminStyle.destaque),
          ],
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icone, this.rotulo, this.valor);

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AdminStyle.destaque.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, size: 18, color: AdminStyle.destaqueClaro),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rotulo,
                style: const TextStyle(
                  color: AutomatizeColors.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                valor,
                style: const TextStyle(
                  color: AutomatizeColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
