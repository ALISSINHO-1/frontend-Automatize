import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/storage/local_storage_service.dart';

/// Painel comercial exclusivo de ADMIN. A API valida todas as operacoes.
class AdminComercialScreen extends StatefulWidget {
  const AdminComercialScreen({super.key, this.client});
  final http.Client? client;
  @override
  State<AdminComercialScreen> createState() => _AdminComercialScreenState();
}

class _AdminComercialScreenState extends State<AdminComercialScreen> {
  bool _ocupado = true;
  String? _erro;
  List<Map<String, dynamic>> _contas = [];
  List<Map<String, dynamic>> _empresas = [];
  static const fundo = Color(0xFF07172A);
  static const painel = Color(0xFF102743);
  static const suave = Color(0xFF9DB1C8);
  static const destaque = Color(0xFF168BFF);

  @override
  void initState() {
    super.initState();
    _recarregar();
  }

  Future<http.Response> _api(String metodo, String path, [Map<String, dynamic>? body]) async {
    final token = await LocalStorageService.getToken();
    if (token == null) throw StateError('Sessão encerrada. Entre novamente.');
    final client = widget.client ?? http.Client();
    try {
      final headers = {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json',
      };
      final url = AppConfig.apiUri(path);
      final result = metodo == 'GET'
          ? await client.get(url, headers: headers)
          : await client.post(url, headers: headers, body: jsonEncode(body ?? {}));
      if (result.statusCode == 401 || result.statusCode == 403) {
        throw StateError('Acesso administrativo não autorizado.');
      }
      if (result.statusCode < 200 || result.statusCode >= 300) {
        throw StateError('Falha na operação. Código: ' + result.statusCode.toString());
      }
      return result;
    } finally {
      if (widget.client == null) client.close();
    }
  }

  List<Map<String, dynamic>> _interpretar(http.Response resposta) {
    final value = jsonDecode(utf8.decode(resposta.bodyBytes));
    if (value is! List) throw const FormatException('Resposta inválida.');
    return value.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _recarregar() async {
    if (mounted) setState(() { _ocupado = true; _erro = null; });
    try {
      final contas = await _api('GET', '/comercial/contas/pendentes');
      final empresas = await _api('GET', '/comercial/organizacoes');
      if (!mounted) return;
      setState(() {
        _contas = _interpretar(contas);
        _empresas = _interpretar(empresas);
      });
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível consultar o módulo comercial.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _aprovar(Map<String, dynamic> conta) async {
    if (conta['email_verificado_em'] == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Aprovar contrato DEV?'),
        content: Text('Você confirmou a contratação de ' +
            (conta['nome']?.toString() ?? 'este cliente') + '? '
            'A conta terá acesso aos próprios projetos e a ação será auditada.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false),
              child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true),
              child: const Text('Aprovar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _ocupado = true);
    try {
      await _api('POST', '/comercial/contas/' +
          (conta['id']?.toString() ?? '') + '/aprovar-dev');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente DEV aprovado.')),
      );
    } catch (_) {
      if (mounted) setState(() => _erro = 'Falha ao aprovar. Verifique o contrato e o e-mail.');
    } finally {
      if (mounted) await _recarregar();
    }
  }

  Future<void> _criarEmpresa() async {
    final nome = TextEditingController();
    final valor = await showDialog<String>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Nova empresa'),
        content: TextField(controller: nome, maxLength: 255,
          decoration: const InputDecoration(labelText: 'Nome da empresa')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo),
              child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, nome.text.trim()),
              child: const Text('Salvar')),
        ],
      ),
    );
    nome.dispose();
    if (!mounted || valor == null || valor.length < 3) return;
    setState(() => _ocupado = true);
    try {
      await _api('POST', '/comercial/organizacoes', {'nome': valor});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empresa cadastrada. SaaS ainda não liberado.')),
      );
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível criar a empresa.');
    } finally {
      if (mounted) await _recarregar();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: fundo,
    appBar: AppBar(
      title: const Text('Clientes e empresas'),
      backgroundColor: fundo,
      actions: [
        IconButton(icon: const Icon(Icons.refresh), tooltip: 'Atualizar',
          onPressed: _ocupado ? null : _recarregar),
      ],
    ),
    body: _ocupado
        ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(24), children: [
            const Text('Cadastro e contratos', style: TextStyle(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Apenas a equipe pode liberar um contrato. '
              'A área SaaS empresarial permanece bloqueada até o isolamento por empresa.',
              style: TextStyle(color: suave)),
            if (_erro != null) Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_erro!, style: const TextStyle(color: Colors.redAccent))),
            const SizedBox(height: 30),
            const Text('Contas pendentes', style: TextStyle(
              color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
            if (_contas.isEmpty) const ListTile(
              title: Text('Nenhuma conta pendente nesta página.')),
            for (final conta in _contas)
              Card(color: painel, child: ListTile(
                title: Text(conta['nome']?.toString() ?? 'Cliente',
                  style: const TextStyle(color: Colors.white)),
                subtitle: Text((conta['email']?.toString() ?? '') + ' • ' +
                  (conta['email_verificado_em'] == null
                    ? 'E-mail não confirmado' : 'E-mail confirmado'),
                  style: const TextStyle(color: suave)),
                trailing: FilledButton(
                  onPressed: conta['email_verificado_em'] == null
                    ? null : () => _aprovar(conta),
                  style: FilledButton.styleFrom(backgroundColor: destaque),
                  child: const Text('Aprovar DEV'),
                ),
              )),
            const SizedBox(height: 24),
            Wrap(alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10, children: [
                const Text('Empresas', style: TextStyle(
                  color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                FilledButton.icon(
                  onPressed: _criarEmpresa,
                  icon: const Icon(Icons.business_rounded),
                  label: const Text('Cadastrar empresa'),
                ),
              ]),
            if (_empresas.isEmpty) const ListTile(
              title: Text('Nenhuma empresa cadastrada nesta página.')),
            for (final empresa in _empresas)
              Card(color: painel, child: ListTile(
                leading: const Icon(Icons.business_outlined, color: destaque),
                title: Text(empresa['nome']?.toString() ?? 'Empresa',
                  style: const TextStyle(color: Colors.white)),
                subtitle: const Text('SaaS ainda não liberado',
                  style: TextStyle(color: suave)),
                trailing: const Icon(Icons.lock_outline, color: suave),
              )),
          ]),
  );
}
