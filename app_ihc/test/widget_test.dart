import 'package:app_ihc/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts at scanner screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Scanner'), findsOneWidget);
    expect(find.text('Simular leitura'), findsOneWidget);
  });
}
