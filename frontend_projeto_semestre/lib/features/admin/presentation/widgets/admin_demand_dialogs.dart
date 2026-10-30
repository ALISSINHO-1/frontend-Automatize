import 'package:flutter/material.dart';

final _uuidRegex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

String? _validarUuid(String? valor, {bool obrigatorio = true}) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) return obrigatorio ? 'Informe o identificador.' : null;
  return _uuidRegex.hasMatch(texto) ? null : 'Identificador inválido (UUID).';
}

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

/// Cadastro (sem [inicial]) ou edição de título/descrição de uma demanda.
class DemandFormDialog extends StatefulWidget {
  const DemandFormDialog({
    super.key,
    this.tituloInicial,
    this.descricaoInicial,
  });

  final String? tituloInicial;
  final String? descricaoInicial;

  bool get _edicao => tituloInicial != null;

  static Future<DemandFormResult?> show(
    BuildContext context, {
    String? tituloInicial,
    String? descricaoInicial,
  }) {
    return showDialog<DemandFormResult>(
      context: context,
      builder: (_) => DemandFormDialog(
        tituloInicial: tituloInicial,
        descricaoInicial: descricaoInicial,
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
  final _cliente = TextEditingController();

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _cliente.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      DemandFormResult(
        titulo: _titulo.text.trim(),
        descricao: _descricao.text.trim(),
        clienteId: _cliente.text.trim().isEmpty ? null : _cliente.text.trim(),
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
                TextFormField(
                  controller: _cliente,
                  decoration: const InputDecoration(
                    labelText: 'ID do cliente',
                    helperText: 'UUID de um usuário com perfil CLIENTE ativo.',
                  ),
                  validator: _validarUuid,
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
          onPressed: _salvar,
          child: Text(widget._edicao ? 'Salvar' : 'Cadastrar'),
        ),
      ],
    );
  }
}

/// A API ainda não lista usuários, então o técnico é informado pelo UUID.
class AssignTechnicianDialog extends StatefulWidget {
  const AssignTechnicianDialog({super.key, this.responsavelAtual});

  final String? responsavelAtual;

  static Future<String?> show(
    BuildContext context, {
    String? responsavelAtual,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) =>
          AssignTechnicianDialog(responsavelAtual: responsavelAtual),
    );
  }

  @override
  State<AssignTechnicianDialog> createState() => _AssignTechnicianDialogState();
}

class _AssignTechnicianDialogState extends State<AssignTechnicianDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _responsavel = TextEditingController(
    text: widget.responsavelAtual,
  );

  @override
  void dispose() {
    _responsavel.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_responsavel.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atribuir técnico'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _responsavel,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'ID do técnico'),
            validator: _validarUuid,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Atribuir')),
      ],
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
