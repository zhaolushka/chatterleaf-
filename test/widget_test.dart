import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatterleaf/main.dart';

void main() {
  testWidgets('Login screen shows Chatterleaf brand', (tester) async {
    await tester.pumpWidget(const ChatterleafApp());
    await tester.pumpAndSettle();

    expect(find.text('Chatterleaf'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('Wrong password shows clear error', (tester) async {
    await tester.pumpWidget(const ChatterleafApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Wrong password'), findsOneWidget);
  });
}
