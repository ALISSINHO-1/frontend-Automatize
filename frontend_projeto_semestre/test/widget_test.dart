import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/app/app.dart';

void main() {
  testWidgets('carrega a estrutura inicial do frontend web', (tester) async {
    await tester.pumpWidget(const FaculdadeApp());

    expect(find.text('Projeto Semestral'), findsWidgets);
    expect(find.text('Frontend Web preparado para evoluir'), findsOneWidget);
    expect(find.text('Somente Web'), findsOneWidget);
    expect(find.text('API configurável'), findsOneWidget);
  });
}
