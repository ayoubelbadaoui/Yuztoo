import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/storefront/application/providers.dart';
import 'package:flutter_yuztoo/feature/storefront/domain/entities/business_hours.dart';

const _morning = TimeSlot(start: '9h', end: '12h30');
const _afternoon = TimeSlot(start: '14h', end: '19h');
const _custom = [TimeSlot(start: '10h', end: '16h')];

List<String> _display(BusinessHours h) =>
    h.allDays.map((d) => d.displayText).toList();

void main() {
  final closedWeek = BusinessHours.fromMap(null);

  group('toggleDay', () {
    test('first opened day gets the default slots', () {
      final h = closedWeek.toggleDay('monday');
      expect(h.monday.isEnabled, isTrue);
      expect(h.monday.timeSlots, BusinessHours.defaultSlots);
    });

    test('opening a day copies the closest earlier open day', () {
      final h = closedWeek
          .toggleDay('monday')
          .withSlotsCascading('monday', const [_morning, _afternoon])
          .toggleDay('tuesday')
          .toggleDay('thursday');

      expect(h.tuesday.timeSlots, const [_morning, _afternoon]);
      expect(h.thursday.timeSlots, const [_morning, _afternoon]);
    });

    test('opening a day before any open day copies the next open one', () {
      final h = closedWeek
          .toggleDay('saturday')
          .withSlotsCascading('saturday', _custom)
          .toggleDay('friday');

      expect(h.friday.timeSlots, _custom);
    });

    test('closing a day clears its slots', () {
      final h = closedWeek.toggleDay('monday').toggleDay('monday');
      expect(h.monday.isEnabled, isFalse);
      expect(h.monday.timeSlots, isEmpty);
    });
  });

  group('withSlotsCascading', () {
    test('editing Monday updates following days that had the same hours', () {
      var h = closedWeek;
      for (final key in ['monday', 'tuesday', 'wednesday', 'saturday']) {
        h = h.toggleDay(key);
      }

      h = h.withSlotsCascading('monday', const [_morning, _afternoon]);

      expect(_display(h), [
        '9h - 12h30   14h - 19h',
        '9h - 12h30   14h - 19h',
        '9h - 12h30   14h - 19h',
        'Fermé',
        'Fermé',
        '9h - 12h30   14h - 19h',
        'Fermé',
      ]);
    });

    test('days with their own hours are not overwritten', () {
      var h = closedWeek
          .toggleDay('monday')
          .toggleDay('tuesday')
          .toggleDay('wednesday');
      h = h.withSlotsCascading('wednesday', _custom);

      h = h.withSlotsCascading('monday', const [_morning]);

      expect(h.monday.timeSlots, const [_morning]);
      expect(h.tuesday.timeSlots, const [_morning]);
      expect(h.wednesday.timeSlots, _custom);
    });

    test('earlier days are never changed', () {
      var h = closedWeek.toggleDay('monday').toggleDay('tuesday');

      h = h.withSlotsCascading('tuesday', _custom);

      expect(h.monday.timeSlots, BusinessHours.defaultSlots);
      expect(h.tuesday.timeSlots, _custom);
    });

    test('profile editor: opening a day reuses the previous open day', () {
      final notifier = BusinessHoursNotifier(closedWeek)
        ..toggleDay('Lundi', true)
        ..updateDayHours('Lundi', const [_morning, _afternoon])
        ..toggleDay('Mardi', true);

      expect(notifier.state.tuesday.timeSlots, const [_morning, _afternoon]);
      notifier.dispose();
    });

    test('result round-trips through Firestore map', () {
      final h = closedWeek
          .toggleDay('monday')
          .toggleDay('tuesday')
          .withSlotsCascading('monday', const [_morning]);

      expect(_display(BusinessHours.fromMap(h.toMap())), _display(h));
    });
  });
}
