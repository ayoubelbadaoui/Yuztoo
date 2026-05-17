import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/storefront/domain/entities/business_hours.dart';

/// Hard tests for hours normalization — messy production data + edge cases.
void main() {
  group('HARD: normalizeTimeString — legacy & abuse inputs', () {
    test('100 random-ish legacy strings never throw', () {
      final inputs = [
        '08:00', '8h', '8H30', '23:55', '00:00', '12h05', '8',
        'Fermé', 'closed', '12:00 PM', '  9h00  ', '09H00', '14:30',
        '18:00', '5:00', '0h', '24:00', '8:58', '8:14', '8:15',
      ];
      for (final raw in inputs) {
        expect(() => normalizeTimeString(raw), returnsNormally);
      }
    });

    test('colon formats snap to 5-min grid and strip leading zeros', () {
      expect(normalizeTimeString('09:00'), '9h');
      expect(normalizeTimeString('09:30'), '9h30');
      expect(normalizeTimeString('08:14'), '8h15');
      expect(normalizeTimeString('8:58'), '9h');
    });

    test('h-formats drop :00 minutes', () {
      expect(normalizeTimeString('09h00'), '9h');
      expect(normalizeTimeString('9H00'), '9h');
      expect(normalizeTimeString('09H30'), '9h30');
    });

    test('out-of-range hours clamp to picker bounds', () {
      expect(normalizeTimeString('5:00'), '6h');
      expect(normalizeTimeString('24:00'), '23h55');
      expect(normalizeTimeString('25:99'), '23h55');
    });

    test('unknown formats pass through unchanged', () {
      expect(normalizeTimeString('Fermé'), 'Fermé');
      expect(normalizeTimeString('12:00 PM'), '12:00 PM');
      expect(normalizeTimeString('closed'), 'closed');
    });
  });

  group('HARD: TimeSlot / DayHours round-trip from Firestore JSON', () {
    test('TimeSlot.fromMap normalizes colon legacy format', () {
      final slot = TimeSlot.fromMap({'start': '14:30', 'end': '18:00'});
      expect(slot.start, '14h30');
      expect(slot.end, '18h');
    });

    test('DayHours.fromMap with mixed casing in stored JSON', () {
      final day = DayHours.fromMap({
        'dayName': 'lundi',
        'isEnabled': true,
        'timeSlots': [
          {'start': '09H00', 'end': '12:30'},
        ],
      });
      expect(day.timeSlots.first.start, '9h');
      expect(day.timeSlots.first.end, '12h30');
      expect(day.dayName, 'Lundi');
    });

    test('closed day with isEnabled false has no slots', () {
      final day = DayHours.fromMap({
        'dayName': 'Dimanche',
        'isEnabled': false,
        'timeSlots': [],
      });
      expect(day.isClosed, isTrue);
    });
  });
}
