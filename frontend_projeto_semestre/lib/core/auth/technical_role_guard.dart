import 'package:flutter/material.dart';

import '../../features/home/data/current_user_service.dart';
import '../storage/local_storage_service.dart';

class TechnicalRoleGuard extends StatefulWidget {
  const TechnicalRoleGuard({super.key, required this.child});

  final Widget child;

  @override
  State<TechnicalRoleGuard> createState() => _TechnicalRoleGuardState();
}

class _TechnicalRoleGuardState extends State<TechnicalRoleGuard> {
  late Future<bool> _accessFuture;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _accessFuture = _checkAccess();
  }

  Future<bool> _checkAccess() async {
    final token = await LocalStorageService.getToken();

    if (token == null || token.trim().isEmpty) {
      _errorMessage = 'Você precisa entrar na plataforma.';
      return false;
    }

    final service = CurrentUserService();

    try {
      final user = await service.fetchCurrentUser(token);

      if (user.role != CurrentUserRole.tecnico) {
        _errorMessage = 'Esta área é exclusiva para técnicos.';
        return false;
      }

      return true;
    } on CurrentUserException catch (error) {
      if (error.statusCode == 401) {
        LocalStorageService.invalidarSeAtual(token);
      }
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage =
          'Não foi possível validar seu acesso. Verifique a conexão com a API.';
      return false;
    } finally {
      service.dispose();
    }
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _accessFuture = _checkAccess();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _accessFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return widget.child;
        }

        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? 'Acesso não autorizado.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _retry,
                    child: const Text('Tentar novamente'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                    child: const Text('Voltar para o login'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
