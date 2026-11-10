import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/core/theme/app_theme.dart';
import 'package:frontend_projeto_semestre/core/theme/redesign_colors.dart';
import 'package:frontend_projeto_semestre/features/admin/presentation/admin_style.dart';
import 'package:frontend_projeto_semestre/shared/widgets/main_layout.dart';

void main() {
  test('as áreas compartilham cores e estados', () {
    expect(AdminStyle.fundo, AutomatizeColors.background);
    expect(RedesignColors.background, AutomatizeColors.background);
    expect(AdminStyle.card, AutomatizeColors.panel);
    expect(RedesignColors.card, AutomatizeColors.panel);
    expect(AdminStyle.corEstado('PLANEAMENTO'), AutomatizeColors.purple);
    expect(AdminStyle.corEstado('EXECUCAO'), AutomatizeColors.primary);
    expect(AdminStyle.corEstado('HOMOLOGACAO'), AutomatizeColors.warning);
    expect(AdminStyle.corEstado('CONCLUIDO'), AutomatizeColors.success);
  });

  testWidgets('navegação entre páginas não exige slide', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      routes: {'/segunda': (_) => const Scaffold(body: Text('Segunda página'))},
      home: Builder(builder: (context) => TextButton(
        onPressed: () => Navigator.of(context).pushNamed('/segunda'),
        child: const Text('Abrir'),
      )),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Segunda página'), findsOneWidget);
  });
}
