import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Device/emulator smoke: proves `integration_test` is wired.
/// Full Firebase-backed flows come later (emulator + signed-in fixtures).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('integration_test binding pumps a widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Yuztoo')),
        ),
      ),
    );

    expect(find.text('Yuztoo'), findsOneWidget);
  });
}
