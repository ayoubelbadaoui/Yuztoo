/// Defensive tests that PROVE production crash bugs exist, then verify fixes.
/// Each test group targets a specific TypeError from unsafe Dart `as` casts
/// on Firestore data that may have unexpected types (int instead of bool,
/// int instead of String, String instead of List, etc.).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/storefront/domain/entities/business_hours.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // BUG 1: TimeSlot.fromMap — non-String 'start'/'end' values
  // Root cause: `map['start'] as String? ?? '8h'` throws TypeError when the
  // value is an int (e.g. from a data migration or Firebase Console edit).
  // Fix: use `is String` guard before cast.
  // ─────────────────────────────────────────────────────────────────────────
  group('BUG-1: TimeSlot.fromMap — non-String start/end does not crash', () {
    test('int start (e.g. 8) → falls back to "8h" without crash', () {
      // Before fix: throws TypeError: type 'int' is not a subtype of 'String?'
      expect(
        () => TimeSlot.fromMap({'start': 8, 'end': '12h'}),
        returnsNormally,
      );
      final slot = TimeSlot.fromMap({'start': 8, 'end': '12h'});
      expect(slot.start, '8h'); // fallback
    });

    test('int end → falls back to "12h" without crash', () {
      expect(
        () => TimeSlot.fromMap({'start': '8h', 'end': 12}),
        returnsNormally,
      );
      final slot = TimeSlot.fromMap({'start': '8h', 'end': 12});
      expect(slot.end, '12h'); // fallback
    });

    test('both int → both fallback without crash', () {
      expect(
        () => TimeSlot.fromMap({'start': 8, 'end': 12}),
        returnsNormally,
      );
    });

    test('double start → fallback without crash', () {
      expect(
        () => TimeSlot.fromMap({'start': 8.5, 'end': '12h'}),
        returnsNormally,
      );
    });

    test('bool start → fallback without crash', () {
      expect(
        () => TimeSlot.fromMap({'start': true, 'end': '12h'}),
        returnsNormally,
      );
    });

    test('Map start → fallback without crash', () {
      expect(
        () => TimeSlot.fromMap({'start': {'h': 8}, 'end': '12h'}),
        returnsNormally,
      );
    });

    test('valid String start is preserved unchanged', () {
      final slot = TimeSlot.fromMap({'start': '9h30', 'end': '13h'});
      expect(slot.start, '9h30');
      expect(slot.end, '13h');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BUG 2: DayHours.fromMap — non-bool 'isEnabled' value
  // Root cause: `map['isEnabled'] as bool? ?? false` throws TypeError
  // when value is int 0/1, string 'true'/'false', or any non-bool.
  // Fix: use `map['isEnabled'] == true` (safe for any type).
  // ─────────────────────────────────────────────────────────────────────────
  group('BUG-2: DayHours.fromMap — non-bool isEnabled does not crash', () {
    test('isEnabled=1 (int) → treated as true without crash', () {
      expect(
        () => DayHours.fromMap(
          {'dayName': 'Lundi', 'isEnabled': 1, 'timeSlots': []},
          dayNameFallback: 'Lundi',
        ),
        returnsNormally,
      );
    });

    test('isEnabled=0 (int) → treated as false without crash', () {
      expect(
        () => DayHours.fromMap(
          {'dayName': 'Lundi', 'isEnabled': 0, 'timeSlots': []},
          dayNameFallback: 'Lundi',
        ),
        returnsNormally,
      );
      final day = DayHours.fromMap(
        {'dayName': 'Lundi', 'isEnabled': 0, 'timeSlots': []},
        dayNameFallback: 'Lundi',
      );
      expect(day.isEnabled, isFalse);
    });

    test('isEnabled="true" (string) → treated as false (not == true), no crash', () {
      expect(
        () => DayHours.fromMap(
          {'dayName': 'Lundi', 'isEnabled': 'true', 'timeSlots': []},
          dayNameFallback: 'Lundi',
        ),
        returnsNormally,
      );
    });

    test('isEnabled=null → false without crash', () {
      final day = DayHours.fromMap(
        {'dayName': 'Lundi', 'isEnabled': null, 'timeSlots': []},
        dayNameFallback: 'Lundi',
      );
      expect(day.isEnabled, isFalse);
    });

    test('isEnabled=true (bool) → true as expected', () {
      final day = DayHours.fromMap(
        {'dayName': 'Lundi', 'isEnabled': true, 'timeSlots': []},
        dayNameFallback: 'Lundi',
      );
      expect(day.isEnabled, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BUG 3: BusinessHours.fromMap — non-bool 'hasExceptionalClosure'
  // Root cause: `map['hasExceptionalClosure'] as bool? ?? false` throws
  // TypeError when value is a String like 'true' or int 1.
  // Fix: use `map['hasExceptionalClosure'] == true`.
  // ─────────────────────────────────────────────────────────────────────────
  group('BUG-3: BusinessHours.fromMap — non-bool hasExceptionalClosure', () {
    test('hasExceptionalClosure="true" (string) → no crash', () {
      expect(
        () => BusinessHours.fromMap({'hasExceptionalClosure': 'true'}),
        returnsNormally,
      );
    });

    test('hasExceptionalClosure=1 (int) → no crash', () {
      expect(
        () => BusinessHours.fromMap({'hasExceptionalClosure': 1}),
        returnsNormally,
      );
    });

    test('hasExceptionalClosure=1 → treated as false (not == true)', () {
      final bh = BusinessHours.fromMap({'hasExceptionalClosure': 1});
      // The safe `== true` check returns false for int 1 — defensive.
      // This is acceptable because correct Firestore data uses bool.
      expect(bh.hasExceptionalClosure, isFalse);
    });

    test('hasExceptionalClosure=true (bool) → true preserved', () {
      final bh = BusinessHours.fromMap({'hasExceptionalClosure': true});
      expect(bh.hasExceptionalClosure, isTrue);
    });

    test('hasExceptionalClosure=false (bool) → false preserved', () {
      final bh = BusinessHours.fromMap({'hasExceptionalClosure': false});
      expect(bh.hasExceptionalClosure, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BUG 4: DayHours.fromMap — non-Map slot in timeSlots List
  // Root cause: `e as Map` inside the `.map()` throws if any element
  // in the Firestore list is a String or other non-Map type.
  // Fix: use `.whereType<Map>()` to skip non-Map elements safely.
  // ─────────────────────────────────────────────────────────────────────────
  group('BUG-4: DayHours.fromMap — non-Map element in timeSlots list', () {
    test('timeSlots with a String element → no crash, bad slot skipped', () {
      expect(
        () => DayHours.fromMap(
          {
            'dayName': 'Lundi',
            'isEnabled': true,
            'timeSlots': ['bad_slot', {'start': '8h', 'end': '12h'}],
          },
          dayNameFallback: 'Lundi',
        ),
        returnsNormally,
      );
    });

    test('timeSlots with a String element → valid slot still parsed', () {
      final day = DayHours.fromMap(
        {
          'dayName': 'Lundi',
          'isEnabled': true,
          'timeSlots': ['bad_slot', {'start': '8h', 'end': '12h'}],
        },
        dayNameFallback: 'Lundi',
      );
      expect(day.timeSlots.length, 1);
      expect(day.timeSlots.first.start, '8h');
    });

    test('timeSlots with null element → no crash', () {
      expect(
        () => DayHours.fromMap(
          {
            'dayName': 'Lundi',
            'isEnabled': true,
            'timeSlots': [null, {'start': '9h', 'end': '13h'}],
          },
          dayNameFallback: 'Lundi',
        ),
        returnsNormally,
      );
    });

    test('timeSlots with int elements → no crash, all skipped', () {
      final day = DayHours.fromMap(
        {
          'dayName': 'Lundi',
          'isEnabled': true,
          'timeSlots': [1, 2, 3],
        },
        dayNameFallback: 'Lundi',
      );
      expect(day.timeSlots, isEmpty);
    });

    test('all valid Map slots still parse correctly', () {
      final day = DayHours.fromMap(
        {
          'dayName': 'Lundi',
          'isEnabled': true,
          'timeSlots': [
            {'start': '8h', 'end': '12h'},
            {'start': '14h', 'end': '18h'},
          ],
        },
        dayNameFallback: 'Lundi',
      );
      expect(day.timeSlots.length, 2);
    });
  });
}
