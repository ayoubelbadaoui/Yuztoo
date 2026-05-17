import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/client_notification/domain/promotion_segment_matching.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/auto_notification_triggers.dart';
import 'package:flutter_yuztoo/feature/rappels/presentation/widgets/trigger_grid.dart';

/// Hard tests — Dart/TS contract + segment parity for auto-notifications.
void main() {
  group('HARD: trigger contract Flutter ↔ Cloud Functions', () {
    test('triggerLabels length matches grid count', () {
      expect(triggerLabels.length, 11);
    });

    test('every trigger label is non-empty and unique', () {
      expect(triggerLabels.toSet().length, triggerLabels.length);
      for (final t in triggerLabels) {
        expect(t.trim(), isNotEmpty);
      }
    });

    test('wired triggers set is consistent with visitDetected exception', () {
      for (final t in AutoNotificationTriggers.triggerLabels) {
        if (t == AutoNotificationTriggers.visitDetected) {
          expect(AutoNotificationTriggers.isWiredInCloud(t), isFalse);
        } else {
          expect(AutoNotificationTriggers.isWiredInCloud(t), isTrue);
        }
      }
    });
  });

  group('HARD: segment matrix — promotion targeting (Dart)', () {
    const segments = ['vip', 'habitue', 'nouveau', 'inactif'];
    const targetsList = <List<String>>[
      ['vip'],
      ['soutien'],
      ['habitue'],
      ['nouveau'],
      ['inactif'],
      ['abonne'],
      ['vip', 'nouveau'],
      ['soutien', 'habitue'],
    ];

    for (final seg in segments) {
      for (final targets in targetsList) {
        test('seg=$seg targets=$targets', () {
          final match = promotionSegmentMatchesTarget(seg, targets);
          final viaSoutien = targets.contains('soutien') &&
              (seg == 'vip' || seg == 'habitue');
          // abonne is UI-only; Dart matcher does not map abonne → nouveau
          final viaDirect = targets.contains(seg);
          expect(match, viaSoutien || viaDirect);
        });
      }
    }

    test('empty targets → no match (promo "Tous" uses empty list upstream)', () {
      for (final seg in segments) {
        expect(promotionSegmentMatchesTarget(seg, []), isFalse);
      }
    });

    test('abonne target does not match nouveau in Dart (CF normalizes abonne)', () {
      expect(promotionSegmentMatchesTarget('nouveau', ['abonne']), isFalse);
    });
  });

  group('HARD: birthday / inactive business rules (mirrors CF)', () {
    bool birthdayAllowed({
      required String? dob,
      required String todayMd,
      required int todayYear,
      required int? lastSentYear,
    }) {
      if (dob == null || dob.isEmpty) return false;
      final dobMd = dob.length >= 5 ? dob.substring(dob.length - 5) : dob;
      if (dobMd != todayMd) return false;
      return lastSentYear != todayYear;
    }

    test('no DOB → no birthday notif', () {
      expect(
        birthdayAllowed(dob: null, todayMd: '05-07', todayYear: 2026, lastSentYear: null),
        isFalse,
      );
    });

    test('double send same year blocked', () {
      expect(
        birthdayAllowed(
          dob: '1990-05-07',
          todayMd: '05-07',
          todayYear: 2026,
          lastSentYear: 2026,
        ),
        isFalse,
      );
    });

    bool inactiveAllowed({
      required double daysSinceVisit,
      required int? daysSinceLastNotif,
    }) {
      if (daysSinceVisit < 60) return false;
      if (daysSinceLastNotif == null) return true;
      return daysSinceLastNotif >= 30;
    }

    test('inactive spam guard', () {
      expect(inactiveAllowed(daysSinceVisit: 90, daysSinceLastNotif: 5), isFalse);
      expect(inactiveAllowed(daysSinceVisit: 90, daysSinceLastNotif: 30), isTrue);
    });
  });
}
