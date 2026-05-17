import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/rappels/presentation/widgets/notifications_auto_entry.dart';

void main() {
  group('NotificationsAutoEntry — S2 single entry point', () {
    testWidgets('renders CTA and fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationsAutoEntry(onTap: () => tapped = true),
          ),
        ),
      );

      expect(find.text('Notifications automatiques'), findsOneWidget);
      await tester.tap(find.text('Notifications automatiques'));
      expect(tapped, isTrue);
    });
  });
}
