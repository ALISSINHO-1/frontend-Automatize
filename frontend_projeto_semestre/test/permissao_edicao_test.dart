import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_projeto_semestre/features/home/presentation/pages/permissao_edicao.dart';

void main() {
  group('Permissões de edição de demandas', () {
    test('Cliente dono pode editar demanda em planejamento', () {
      final permitido = usuarioPodeEditarDemanda(
        perfil: 'CLIENTE',
        idUsuario: 'cliente-1',
        clienteId: 'cliente-1',
        status: 'PLANEJAMENTO',
      );

      expect(permitido, isTrue);
    });

    test('Cliente dono pode editar demanda em execução', () {
      final permitido = usuarioPodeEditarDemanda(
        perfil: 'CLIENTE',
        idUsuario: 'cliente-1',
        clienteId: 'cliente-1',
        status: 'EXECUCAO',
      );

      expect(permitido, isTrue);
    });

    test('Cliente não pode editar demanda de outro cliente', () {
      final permitido = usuarioPodeEditarDemanda(
        perfil: 'CLIENTE',
        idUsuario: 'cliente-2',
        clienteId: 'cliente-1',
        status: 'PLANEJAMENTO',
      );

      expect(permitido, isFalse);
    });

    test('Administrador pode editar demanda em homologação', () {
      final permitido = usuarioPodeEditarDemanda(
        perfil: 'ADMIN',
        idUsuario: 'admin-1',
        clienteId: 'cliente-1',
        status: 'HOMOLOGACAO',
      );

      expect(permitido, isTrue);
    });

    test('Demanda concluída não pode ser editada', () {
      final permitido = usuarioPodeEditarDemanda(
        perfil: 'ADMIN',
        idUsuario: 'admin-1',
        clienteId: 'cliente-1',
        status: 'CONCLUIDO',
      );

      expect(permitido, isFalse);
    });

    test('Cliente não pode editar demanda concluída', () {
      final permitido = usuarioPodeEditarDemanda(
        perfil: 'CLIENTE',
        idUsuario: 'cliente-1',
        clienteId: 'cliente-1',
        status: 'CONCLUIDO',
      );

      expect(permitido, isFalse);
    });

    test('Perfil desconhecido não recebe permissão', () {
      final permitido = usuarioPodeEditarDemanda(
        perfil: 'DESCONHECIDO',
        idUsuario: 'usuario-1',
        clienteId: 'usuario-1',
        status: 'EXECUCAO',
      );

      expect(permitido, isFalse);
    });

    test('Usuário sem identificação não pode editar', () {
      final permitido = usuarioPodeEditarDemanda(
        perfil: 'CLIENTE',
        idUsuario: '',
        clienteId: 'cliente-1',
        status: 'PLANEJAMENTO',
      );

      expect(permitido, isFalse);
    });
  });
}
