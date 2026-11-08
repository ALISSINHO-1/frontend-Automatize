
import 'package:flutter/material.dart';

import '../../features/admin/data/models/usuario_atual_model.dart';
import '../../features/admin/data/services/usuario_atual_store.dart';
import 'acesso_negado_screen.dart';

/// Restringe uma tela ao perfil CLIENTE.
///
/// A autorização definitiva dos dados continua
/// sendo responsabilidade da API.
class ClienteGuard extends StatefulWidget {
  const ClienteGuard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ClienteGuard> createState() => _ClienteGuardState();
}

class _ClienteGuardState extends State<ClienteGuard> {
  late Future<UsuarioAtualModel?> _usuarioFuture;

  @override
  void initState() {
    super.initState();
    _usuarioFuture = UsuarioAtualStore.instance.carregar();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UsuarioAtualModel?>(
      future: _usuarioFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Não foi possível verificar seu perfil.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _usuarioFuture =
                            UsuarioAtualStore.instance.carregar();
                      });
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final usuario = snapshot.data;

        if (usuario?.perfil == 'CLIENTE') {
          return widget.child;
        }

        return const AcessoNegadoScreen(
          titulo: 'Acesso negado',
          mensagem:
              'Esta área é exclusiva para usuários '
              'com o perfil CLIENTE.',
        );
      },
    );
  }
}
