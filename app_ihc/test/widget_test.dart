import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts at login screen', (tester) async {
    ServiceLocator.instance.setup();
    await tester.pumpWidget(const MyApp());

    expect(find.text('Login'), findsOneWidget);
  });
}
