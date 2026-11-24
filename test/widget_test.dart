import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamyr/data/data.dart';
import 'package:tamyr/main.dart';

// Widget tests run in demo mode (no Firebase).
void main() {
  setUpAll(initServices);
  tearDownAll(() => demoBackend?.dispose());

  testWidgets('Login screen shows the Tamyr brand', (tester) async {
    await tester.pumpWidget(const TamyrApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Tamyr'), findsWidgets);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('Wrong password shows a clear error (M1)', (tester) async {
    await tester.pumpWidget(const TamyrApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Wrong email or password'), findsOneWidget);
  });
}
