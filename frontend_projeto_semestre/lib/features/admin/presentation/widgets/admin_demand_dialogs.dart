import 'package:flutter/material.dart';

import '../../data/models/usuario_model.dart';

/// Mínimo exigido pelo backend para o motivo de uma reatribuição (SCRUM-97).
const tamanhoMinimoMotivo = 10;

class DemandFormResult {
  final String titulo;
  final String descricao;
  final String? clienteId;

  const DemandFormResult({
    required this.titulo,
    required this.descricao,
    this.clienteId,
  });
}

/// Cadastro (sem [tituloInicial]) ou edição de título/descrição de uma demanda.
class DemandFormDialog extends StatefulWidget {
  const DemandFormDialog({
    super.key,
    this.tituloInicial,
    this.descricaoInicial,
    this.clientes = const [],
  });

  final String? tituloInicial;
  final String? descricaoInicial;

  /// Clientes ativos para escolher no cadastro (ignorado na edição).
  final List<UsuarioModel> clientes;

  bool get _edicao => tituloInicial != null;

  static Future<DemandFormResult?> show(
    BuildContext context, {
    String? tituloInicial,
    String? descricaoInicial,
    List<UsuarioModel> clientes = const [],
  }) {
    return showDialog<DemandFormResult>(
      context: context,
      builder: (_) => DemandFormDialog(
        tituloInicial: tituloInicial,
        descricaoInicial: descricaoInicial,
        clientes: clientes,
      ),
    );
  }

  @override
  State<DemandFormDialog> createState() => _DemandFormDialogState();
}

class _DemandFormDialogState extends State<DemandFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.tituloInicial);
  late final _descricao = TextEditingController(text: widget.descricaoInicial);
  String? _clienteId;

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      DemandFormResult(
        titulo: _titulo.text.trim(),
        descricao: _descricao.text.trim(),
        clienteId: _clienteId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget._edicao ? 'Editar demanda' : 'Nova demanda'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titulo,
                autofocus: true,
                maxLength: 255,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Informe o título.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricao,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Informe a descrição.' : null,
              ),
              // O cliente só é definido no cadastro; o backend não deixa trocar depois.
              // Para ADMIN ele é obrigatório: a API recusa com "Informe o cliente da demanda".
              if (!widget._edicao) ...[
                const SizedBox(height: 12),
                SeletorUsuario(
                  rotulo: 'Cliente',
                  usuarios: widget.clientes,
                  vazio: 'Nenhum cliente ativo. Cadastre um em "Usuários".',
                  onChanged: (id) => _clienteId = id,
                  validator: (id) => id == null ? 'Selecione o cliente.' : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          // Sem cliente ativo o cadastro falharia na API: nem habilita.
          onPressed: !widget._edicao && widget.clientes.isEmpty
              ? null
              : _salvar,
          child: Text(widget._edicao ? 'Salvar' : 'Cadastrar'),
        ),
      ],
    );
  }
}

class AtribuicaoResult {
  final String responsavelId;
  final String? motivo;

  const AtribuicaoResult({required this.responsavelId, this.motivo});
}

/// Escolha do técnico entre os técnicos ativos (SCRUM-100). Na troca de um
/// técnico já atribuído o motivo é obrigatório, como no backend (SCRUM-97).
class AssignTechnicianDialog extends StatefulWidget {
  const AssignTechnicianDialog({
    super.key,
    required this.tecnicos,
    this.responsavelAtual,
  });

  final List<UsuarioModel> tecnicos;
  final String? responsavelAtual;

  bool get _troca => responsavelAtual != null;

  static Future<AtribuicaoResult?> show(
    BuildContext context, {
    required List<UsuarioModel> tecnicos,
    String? responsavelAtual,
  }) {
    return showDialog<AtribuicaoResult>(
      context: context,
      builder: (_) => AssignTechnicianDialog(
        tecnicos: tecnicos,
        responsavelAtual: responsavelAtual,
      ),
    );
  }

  @override
  State<AssignTechnicianDialog> createState() => _AssignTechnicianDialogState();
}

class _AssignTechnicianDialogState extends State<AssignTechnicianDialog> {
  final _formKey = GlobalKey<FormState>();
  final _motivo = TextEditingController();
  String? _responsavelId;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      AtribuicaoResult(
        responsavelId: _responsavelId!,
        motivo: widget._troca ? _motivo.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reatribuir ao mesmo técnico não tem efeito (o backend responde 409).
    final opcoes = widget.tecnicos
        .where((t) => t.id != widget.responsavelAtual)
        .toList();
    final atual = widget.tecnicos
        .where((t) => t.id == widget.responsavelAtual)
        .map((t) => t.nome)
        .firstOrNull;
    return AlertDialog(
      title: Text(widget._troca ? 'Trocar técnico' : 'Atribuir técnico'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget._troca) ...[
                Text('Responsável atual: ${atual ?? 'técnico inativo'}'),
                const SizedBox(height: 12),
              ],
              SeletorUsuario(
                rotulo: 'Técnico',
                usuarios: opcoes,
                vazio: 'Nenhum outro técnico ativo. Cadastre um em "Usuários".',
                onChanged: (id) => _responsavelId = id,
                validator: (id) => id == null ? 'Selecione o técnico.' : null,
              ),
              if (widget._troca) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _motivo,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Motivo da troca',
                    helperText: 'Fica registrado na auditoria da demanda.',
                  ),
                  validator: (v) =>
                      (v?.trim().length ?? 0) < tamanhoMinimoMotivo
                      ? 'Descreva o motivo (mínimo $tamanhoMinimoMotivo caracteres).'
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: opcoes.isEmpty ? null : _salvar,
          child: Text(widget._troca ? 'Trocar' : 'Atribuir'),
        ),
      ],
    );
  }
}

/// Lista suspensa de usuários (nome e e-mail); some quando não há opções.
class SeletorUsuario extends StatelessWidget {
  const SeletorUsuario({
    super.key,
    required this.rotulo,
    required this.usuarios,
    required this.vazio,
    required this.onChanged,
    required this.validator,
  });

  final String rotulo;
  final List<UsuarioModel> usuarios;
  final String vazio;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    if (usuarios.isEmpty) {
      return Align(alignment: Alignment.centerLeft, child: Text(vazio));
    }
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(labelText: rotulo),
      items: [
        for (final u in usuarios)
          DropdownMenuItem(
            value: u.id,
            child: Text(
              u.email.isEmpty ? u.nome : '${u.nome} · ${u.email}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }
}

/// Confirmação explícita porque a exclusão não tem desfazer.
Future<bool> confirmarExclusaoDemanda(
  BuildContext context,
  String titulo,
) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Excluir demanda'),
      content: Text('Excluir "$titulo"? Esta ação não pode ser desfeita.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}
