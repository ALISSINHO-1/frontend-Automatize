import 'package:flutter/material.dart';
import '../storage/local_storage_service.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  late final Future<String?> _tokenFuture;
  bool _redirecionamentoAgendado = false;

  @override
  void initState() {
    super.initState();
    _tokenFuture = LocalStorageService.getToken();
  }

  void _redirecionarParaLogin() {
    if (_redirecionamentoAgendado) return;

    _redirecionamentoAgendado = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _tokenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;

        if (snapshot.hasError || token == null || token.trim().isEmpty) {
          _redirecionarParaLogin();

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return widget.child;
      },
    );
  }
}
