import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/shared/widgets/time_slot_picker.dart';
import 'package:flutter_yuztoo/feature/storefront/domain/entities/business_hours.dart';
import 'package:flutter_yuztoo/feature/storefront/presentation/widgets/day_row.dart';

void main() {
  group('DayRow — S5 hours UI', () {
    testWidgets('expanded editor uses TimeSlotPicker, not TextField',
        (tester) async {
      const day = DayHours(
        dayName: 'Lundi',
        isEnabled: true,
        timeSlots: [
          TimeSlot(start: '8h', end: '12h'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayRow(
              dayHours: day,
              isDisabled: false,
              otherDayNames: const ['Mardi', 'Mercredi'],
              onToggle: (_) {},
              onSave: (_, __) {},
            ),
          ),
        ),
      );

      await tester.tap(find.textContaining('Voir'));
      await tester.pumpAndSettle();

      expect(find.byType(TimeSlotPicker), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(find.text('Appliquer aussi à'), findsOneWidget);
      expect(find.text('Mar'), findsOneWidget);
      expect(find.text('Mer'), findsOneWidget);
    });

    testWidgets('onSave receives slots and selected other days', (tester) async {
      List<TimeSlot>? saved;
      Set<String>? also;
      const day = DayHours(
        dayName: 'Mardi',
        isEnabled: true,
        timeSlots: [
          TimeSlot(start: '9h', end: '12h'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayRow(
              dayHours: day,
              isDisabled: false,
              otherDayNames: const ['Lundi', 'Mercredi', 'Jeudi'],
              onToggle: (_) {},
              onSave: (slots, alsoApplyTo) {
                saved = slots;
                also = alsoApplyTo;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.textContaining('Voir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mer'));
      await tester.pump();
      await tester.tap(find.text('Enregistrer'));
      await tester.pump();

      expect(saved, isNotNull);
      expect(saved!.length, 1);
      expect(saved!.first.start, '9h');
      expect(also, {'Mercredi'});
    });

    testWidgets('closed day shows Fermé without editor', (tester) async {
      const day = DayHours(
        dayName: 'Dimanche',
        isEnabled: false,
        timeSlots: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayRow(
              dayHours: day,
              isDisabled: false,
              otherDayNames: const ['Lundi'],
              onToggle: (_) {},
              onSave: (_, __) {},
            ),
          ),
        ),
      );

      expect(find.text('Fermé'), findsOneWidget);
      expect(find.byType(TimeSlotPicker), findsNothing);
    });
  });
}
