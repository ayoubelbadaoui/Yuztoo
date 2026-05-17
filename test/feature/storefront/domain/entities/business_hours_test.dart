// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/storefront/domain/entities/business_hours.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // normalizeTimeString
  // ─────────────────────────────────────────────────────────────────────────
  group('normalizeTimeString', () {
    // ── Happy paths ──────────────────────────────────────────────────────
    test('already canonical "8h" → "8h"', () {
      expect(normalizeTimeString('8h'), '8h');
    });

    test('already canonical "8h30" → "8h30"', () {
      expect(normalizeTimeString('8h30'), '8h30');
    });

    test('"08:00" (colon format) → "8h"', () {
      expect(normalizeTimeString('08:00'), '8h');
    });

    test('"08:30" (colon format) → "8h30"', () {
      expect(normalizeTimeString('08:30'), '8h30');
    });

    test('"08h00" → "8h"', () {
      expect(normalizeTimeString('08h00'), '8h');
    });

    test('"8H30" (uppercase H) → "8h30"', () {
      expect(normalizeTimeString('8H30'), '8h30');
    });

    test('"12:00" → "12h"', () {
      expect(normalizeTimeString('12:00'), '12h');
    });

    test('"23:30" → "23h30"', () {
      expect(normalizeTimeString('23:30'), '23h30');
    });

    test('bare integer "8" → "8h"', () {
      expect(normalizeTimeString('8'), '8h');
    });

    test('bare integer "08" → "8h"', () {
      expect(normalizeTimeString('08'), '8h');
    });

    // ── Minute snapping (nearest 5-minute boundary, Cupertino wheel) ───
    test('"8:10" → "8h10"', () {
      expect(normalizeTimeString('8:10'), '8h10');
    });

    test('"8:14" → "8h15"', () {
      expect(normalizeTimeString('8:14'), '8h15');
    });

    test('"8:15" → "8h15"', () {
      expect(normalizeTimeString('8:15'), '8h15');
    });

    test('"8:44" → "8h45"', () {
      expect(normalizeTimeString('8:44'), '8h45');
    });

    test('"8:45" → "8h45"', () {
      expect(normalizeTimeString('8:45'), '8h45');
    });

    test('"8:58" (rolls to next hour) → "9h"', () {
      expect(normalizeTimeString('8:58'), '9h');
    });

    // ── Clamping ─────────────────────────────────────────────────────────
    test('"5:00" → "6h" (clamped to minimum)', () {
      expect(normalizeTimeString('5:00'), '6h');
    });

    test('"0h" → "6h" (clamped)', () {
      expect(normalizeTimeString('0h'), '6h');
    });

    test('"24:00" → "23h55" (clamped to picker max)', () {
      expect(normalizeTimeString('24:00'), '23h55');
    });

    test('"23:45" → "23h45"', () {
      expect(normalizeTimeString('23:45'), '23h45');
    });

    // ── Pass-through for unknown formats ─────────────────────────────────
    test('"Fermé" → unchanged', () {
      expect(normalizeTimeString('Fermé'), 'Fermé');
    });

    test('"12:00 PM" → unchanged', () {
      expect(normalizeTimeString('12:00 PM'), '12:00 PM');
    });

    test('empty string → unchanged', () {
      expect(normalizeTimeString(''), '');
    });

    test('whitespace-padded "  8h  " → "8h"', () {
      expect(normalizeTimeString('  8h  '), '8h');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // TimeSlot
  // ─────────────────────────────────────────────────────────────────────────
  group('TimeSlot', () {
    test('display is "start - end"', () {
      const slot = TimeSlot(start: '8h', end: '12h');
      expect(slot.display, '8h - 12h');
    });

    test('toMap / fromMap round-trips', () {
      const slot = TimeSlot(start: '9h30', end: '13h');
      final map = slot.toMap();
      final restored = TimeSlot.fromMap(map);
      expect(restored.start, slot.start);
      expect(restored.end, slot.end);
    });

    test('fromMap normalizes legacy "08:30" stored start', () {
      final slot = TimeSlot.fromMap({'start': '08:30', 'end': '12:00'});
      expect(slot.start, '8h30');
      expect(slot.end, '12h');
    });

    test('fromMap normalizes mis-cased "8H00" and snaps "8:14" → 8h15', () {
      final slot = TimeSlot.fromMap({'start': '8H00', 'end': '8:14'});
      expect(slot.start, '8h');
      expect(slot.end, '8h15');
    });

    test('fromMap handles null start/end gracefully', () {
      final slot = TimeSlot.fromMap({'start': null, 'end': null});
      // Falls back to '8h' and '12h' defaults.
      expect(slot.start, '8h');
      expect(slot.end, '12h');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // DayHours
  // ─────────────────────────────────────────────────────────────────────────
  group('DayHours', () {
    const openDay = DayHours(
      dayName: 'Lundi',
      isEnabled: true,
      timeSlots: [TimeSlot(start: '8h', end: '12h')],
    );

    const closedDay = DayHours(
      dayName: 'Dimanche',
      isEnabled: false,
      timeSlots: [],
    );

    const enabledButNoSlots = DayHours(
      dayName: 'Mardi',
      isEnabled: true,
      timeSlots: [],
    );

    test('isClosed is false when enabled + slots', () {
      expect(openDay.isClosed, isFalse);
    });

    test('isClosed is true when isEnabled false', () {
      expect(closedDay.isClosed, isTrue);
    });

    test('isClosed is true when enabled but no slots', () {
      expect(enabledButNoSlots.isClosed, isTrue);
    });

    test('displayText is "Fermé" for closed day', () {
      expect(closedDay.displayText, 'Fermé');
    });

    test('displayText shows slot times for open day', () {
      expect(openDay.displayText, '8h - 12h');
    });

    test('displayText joins multiple slots', () {
      const twoSlots = DayHours(
        dayName: 'Mercredi',
        isEnabled: true,
        timeSlots: [
          TimeSlot(start: '8h', end: '12h'),
          TimeSlot(start: '14h', end: '18h'),
        ],
      );
      expect(twoSlots.displayText, contains('8h - 12h'));
      expect(twoSlots.displayText, contains('14h - 18h'));
    });

    test('toMap / fromMap round-trips', () {
      final map = openDay.toMap();
      final restored = DayHours.fromMap(map, dayNameFallback: 'Lundi');
      expect(restored.dayName, 'Lundi');
      expect(restored.isEnabled, isTrue);
      expect(restored.timeSlots.length, 1);
      expect(restored.timeSlots.first.start, '8h');
    });

    test('fromMap with empty map → closed day with fallback name', () {
      final day = DayHours.fromMap({}, dayNameFallback: 'Jeudi');
      expect(day.isEnabled, isFalse);
      expect(day.dayName, 'Jeudi');
      expect(day.timeSlots, isEmpty);
    });

    test('fromMap normalizes day name to title-case', () {
      final day = DayHours.fromMap(
        {'dayName': 'lundi', 'isEnabled': true, 'timeSlots': []},
        dayNameFallback: 'X',
      );
      expect(day.dayName, 'Lundi');
    });

    test('fromMap with non-list timeSlots does not throw', () {
      final day = DayHours.fromMap(
        {'dayName': 'Mardi', 'isEnabled': true, 'timeSlots': 'bad'},
        dayNameFallback: 'Mardi',
      );
      expect(day.timeSlots, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BusinessHours
  // ─────────────────────────────────────────────────────────────────────────
  group('BusinessHours', () {
    test('fromMap(null) → all days closed, no exceptional closure', () {
      final bh = BusinessHours.fromMap(null);
      for (final day in bh.allDays) {
        expect(day.isClosed, isTrue, reason: '${day.dayName} should be closed');
      }
      expect(bh.hasExceptionalClosure, isFalse);
    });

    test('fromMap({}) → all days closed', () {
      final bh = BusinessHours.fromMap({});
      expect(bh.allDays.every((d) => d.isClosed), isTrue);
    });

    test('allDays returns 7 entries', () {
      final bh = BusinessHours.fromMap(null);
      expect(bh.allDays.length, 7);
    });

    test('toMap / fromMap round-trips preserving hasExceptionalClosure', () {
      const bh = BusinessHours(
        monday: DayHours(
          dayName: 'Lundi',
          isEnabled: true,
          timeSlots: [TimeSlot(start: '8h', end: '12h')],
        ),
        tuesday:
            DayHours(dayName: 'Mardi', isEnabled: false, timeSlots: []),
        wednesday:
            DayHours(dayName: 'Mercredi', isEnabled: false, timeSlots: []),
        thursday:
            DayHours(dayName: 'Jeudi', isEnabled: false, timeSlots: []),
        friday: DayHours(
          dayName: 'Vendredi',
          isEnabled: true,
          timeSlots: [TimeSlot(start: '9h', end: '17h')],
        ),
        saturday:
            DayHours(dayName: 'Samedi', isEnabled: false, timeSlots: []),
        sunday:
            DayHours(dayName: 'Dimanche', isEnabled: false, timeSlots: []),
        hasExceptionalClosure: true,
      );

      final map = bh.toMap();
      final restored = BusinessHours.fromMap(map);

      expect(restored.hasExceptionalClosure, isTrue);
      expect(restored.monday.isEnabled, isTrue);
      expect(restored.monday.timeSlots.first.start, '8h');
      expect(restored.friday.isEnabled, isTrue);
      expect(restored.friday.timeSlots.first.end, '17h');
      expect(restored.tuesday.isClosed, isTrue);
    });

    test('fromMap parses hasExceptionalClosure = false', () {
      final bh = BusinessHours.fromMap({'hasExceptionalClosure': false});
      expect(bh.hasExceptionalClosure, isFalse);
    });

    test('fromMap defaults hasExceptionalClosure to false when missing', () {
      final bh = BusinessHours.fromMap({'monday': {}});
      expect(bh.hasExceptionalClosure, isFalse);
    });

    test('fromMap with malformed day sub-map still produces valid struct', () {
      final bh = BusinessHours.fromMap({
        'monday': 'bad_value',
        'hasExceptionalClosure': false,
      });
      expect(bh.monday.isClosed, isTrue);
    });

    test('day names fallback correctly when dayName missing in sub-map', () {
      final bh = BusinessHours.fromMap({
        'wednesday': {'isEnabled': true, 'timeSlots': []},
      });
      expect(bh.wednesday.dayName, 'Mercredi');
    });
  });
}
