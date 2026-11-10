import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/widgets/admin_layout.dart';

void main() {
  testWidgets('menu técnico abre no celular e não lista páginas provisórias', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: AdminLayout(child: Center(child: Text('Área técnica'))),
    ));
    await tester.pumpAndSettle();

    final botaoMenu = find.byTooltip('Abrir menu de navegação');
    expect(botaoMenu, findsOneWidget);
    await tester.tap(botaoMenu);
    await tester.pumpAndSettle();

    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Demandas'), findsOneWidget);
    expect(find.text('Histórico'), findsNothing);
    expect(find.text('Anexos'), findsNothing);
  });
}
