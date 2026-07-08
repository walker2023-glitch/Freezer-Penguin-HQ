// Smoke test — verifies that FreezerPenguinApp renders the LoginScreen
// (the initial unauthenticated route) without throwing.

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_mobile/main.dart';

void main() {
  testWidgets('App renders LoginScreen when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FreezerPenguinApp());
    // LoginScreen shows the app title — verify it appears.
    expect(find.text('Freezer Penguin'), findsWidgets);
  });
}
