import 'package:flutter/material.dart';

import '../../../../shared/widgets/main_layout.dart';
import '../../data/models/usuario_atual_model.dart';
import '../../data/services/usuario_atual_store.dart';
import '../admin_style.dart';

/// Libera [child] só para o perfil ADMIN (SCRUM-76).
///
/// Esconder a tela é só conveniência: o backend recusa com 403 qualquer
/// operação administrativa de outro perfil, então a regra real fica lá.
class AdminGuard extends StatefulWidget {
  const AdminGuard({super.key, required this.child});

  final Widget child;

  @override
  State<AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<AdminGuard> {
  late Future<UsuarioAtualModel?> _usuario = UsuarioAtualStore.instance
      .carregar();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UsuarioAtualModel?>(
      future: _usuario,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AdminStyle.fundo,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data?.isAdmin == true) return widget.child;
        return _AcessoNegado(
          erro: snapshot.hasError ? '${snapshot.error}' : null,
          onTentarNovamente: () =>
              setState(() => _usuario = UsuarioAtualStore.instance.carregar()),
        );
      },
    );
  }
}

/// Mostra [child] (item de menu) só quando o usuário da sessão é ADMIN.
class AdminMenuGate extends StatefulWidget {
  const AdminMenuGate({super.key, required this.child});

  final Widget child;

  @override
  State<AdminMenuGate> createState() => _AdminMenuGateState();
}

class _AdminMenuGateState extends State<AdminMenuGate> {
  @override
  void initState() {
    super.initState();
    // Falha aqui só esconde o item; a tela admin trata o erro ao abrir.
    UsuarioAtualStore.instance.carregar().catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UsuarioAtualModel?>(
      valueListenable: UsuarioAtualStore.instance,
      builder: (context, usuario, _) =>
          usuario?.isAdmin == true ? widget.child : const SizedBox.shrink(),
    );
  }
}

class _AcessoNegado extends StatelessWidget {
  const _AcessoNegado({this.erro, required this.onTentarNovamente});

  final String? erro;
  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminStyle.fundo,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: AdminStyle.caixa(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                erro == null
                    ? Icons.lock_outline_rounded
                    : Icons.cloud_off_rounded,
                color: AutomatizeColors.warning,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                erro == null
                    ? 'Acesso restrito'
                    : 'Não foi possível verificar seu perfil',
                style: AdminStyle.tituloCard,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                erro ??
                    'O painel administrativo é exclusivo para o perfil ADMIN.',
                style: AdminStyle.subtitulo,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Voltar'),
                  ),
                  if (erro != null)
                    FilledButton(
                      onPressed: onTentarNovamente,
                      child: const Text('Tentar novamente'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
