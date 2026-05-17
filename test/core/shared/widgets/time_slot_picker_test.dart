import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/shared/widgets/time_slot_picker.dart';

void main() {
  group('TimeSlotPicker — S5 hours (no free text)', () {
    testWidgets('shows Début/Fin chips with canonical labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSlotPicker(
              startTime: '8h30',
              endTime: '12h',
              onStartChanged: (_) {},
              onEndChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('8h30'), findsOneWidget);
      expect(find.text('12h'), findsOneWidget);
      expect(find.text('Début'), findsOneWidget);
      expect(find.text('Fin'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('tap opens Cupertino time wheel, not a keyboard field',
        (tester) async {
      String? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSlotPicker(
              startTime: '8h',
              endTime: '12h',
              onStartChanged: (v) => picked = v,
              onEndChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('8h'));
      await tester.pumpAndSettle();

      expect(find.text('Choisir l\'heure'), findsOneWidget);
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked, matches(RegExp(r'^\d{1,2}h(\d{2})?$')));
    });

    testWidgets('legacy colon seed normalizes when picker opens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSlotPicker(
              startTime: '08:30',
              endTime: '12:00',
              onStartChanged: (_) {},
              onEndChanged: (_) {},
            ),
          ),
        ),
      );

      // Display uses raw props; picker normalizes on open via normalizeTimeString.
      await tester.tap(find.text('08:30'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
    });
  });
}
