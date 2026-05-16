import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/rappels/presentation/widgets/audience_section.dart';

void main() {
  group('AudienceSection — mal corrigé S4', () {
    testWidgets('shows Soutien chip when Certains clients selected',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudienceSection(
              selectedIndex: 1,
              onChanged: (_) {},
              targetSegments: const ['soutien'],
              onSegmentToggled: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Soutien'), findsOneWidget);
      expect(find.text('VIP'), findsOneWidget);
      expect(find.text('Habitué'), findsOneWidget);
    });

    testWidgets('hides segment chips when Tous mes clients selected',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudienceSection(
              selectedIndex: 0,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Soutien'), findsNothing);
      expect(find.text('Cibler les segments'), findsNothing);
    });

    testWidgets('tapping Soutien invokes onSegmentToggled', (tester) async {
      String? toggled;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudienceSection(
              selectedIndex: 1,
              onChanged: (_) {},
              onSegmentToggled: (k) => toggled = k,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Soutien'));
      expect(toggled, 'soutien');
    });
  });
}
