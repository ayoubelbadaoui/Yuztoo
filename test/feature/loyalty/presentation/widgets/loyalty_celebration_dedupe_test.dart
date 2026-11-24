import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/active_validation_request.dart';
import 'package:flutter_yuztoo/feature/loyalty/presentation/widgets/loyalty_celebration_dedupe.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';

ActiveValidationRequest _session({
  required String merchantId,
  required ActiveValidationStatus status,
  DateTime? completedAt,
  String clientUid = 'c1',
}) {
  return ActiveValidationRequest(
    merchantId: merchantId,
    clientUid: clientUid,
    clientDisplayName: 'Client',
    status: status,
    programSnapshot: LoyaltyProgramConfig.initial(),
    completedAt: completedAt,
    resultValidatedDelta: status == ActiveValidationStatus.completed ? 1 : null,
  );
}

void main() {
  group('LoyaltyCelebrationDedupe.sessionKey', () {
    test('uses completedAt millis when present', () {
      final at = DateTime.utc(2026, 10, 28, 12);
      final s = _session(
        merchantId: 'm1',
        status: ActiveValidationStatus.completed,
        completedAt: at,
      );
      expect(
        LoyaltyCelebrationDedupe.sessionKey(s),
        'm1__c1__${at.millisecondsSinceEpoch}',
      );
    });

    test('falls back to stable completed suffix when completedAt is null', () {
      final s = _session(
        merchantId: 'm1',
        status: ActiveValidationStatus.completed,
      );
      expect(LoyaltyCelebrationDedupe.sessionKey(s), 'm1__c1__completed');
    });

    test('falls back to cancelled suffix for cancelled without timestamp', () {
      final s = _session(
        merchantId: 'm1',
        status: ActiveValidationStatus.cancelled,
      );
      expect(LoyaltyCelebrationDedupe.sessionKey(s), 'm1__c1__cancelled');
    });
  });

  group('LoyaltyCelebrationDedupe.parsePersistedKeys / encode', () {
    test('parses JSON list and merges legacy single key', () {
      final keys = LoyaltyCelebrationDedupe.parsePersistedKeys(
        jsonList: jsonEncode(<String>['a__b__1', 'c__d__2']),
        legacySingle: 'legacy__key',
      );
      expect(keys, containsAll(<String>['a__b__1', 'c__d__2', 'legacy__key']));
    });

    test('tolerates corrupt JSON', () {
      final keys = LoyaltyCelebrationDedupe.parsePersistedKeys(
        jsonList: 'not-json',
        legacySingle: 'only',
      );
      expect(keys, <String>{'only'});
    });

    test('encode caps at maxPersistedKeys keeping newest tail', () {
      final many = <String>{
        for (var i = 0; i < LoyaltyCelebrationDedupe.maxPersistedKeys + 10; i++)
          'k$i',
      };
      final encoded = LoyaltyCelebrationDedupe.encodePersistedKeys(many);
      final decoded = (jsonDecode(encoded) as List).cast<String>();
      expect(decoded.length, LoyaltyCelebrationDedupe.maxPersistedKeys);
      expect(decoded.last, 'k${LoyaltyCelebrationDedupe.maxPersistedKeys + 9}');
    });

    test('retains keys for two merchants', () {
      final set = <String>{'m1__c1__100', 'm2__c1__200'};
      final roundTrip = LoyaltyCelebrationDedupe.parsePersistedKeys(
        jsonList: LoyaltyCelebrationDedupe.encodePersistedKeys(set),
      );
      expect(roundTrip, set);
    });
  });

  group('LoyaltyCelebrationDedupe.isLiveTerminalTransition', () {
    test('false when previous is null (cold first snapshot)', () {
      final completed = _session(
        merchantId: 'm1',
        status: ActiveValidationStatus.completed,
        completedAt: DateTime.utc(2026, 1, 1),
      );
      expect(
        LoyaltyCelebrationDedupe.isLiveTerminalTransition(
          previous: null,
          session: completed,
        ),
        isFalse,
      );
    });

    test('true for awaiting → completed', () {
      final awaiting = _session(
        merchantId: 'm1',
        status: ActiveValidationStatus.awaiting,
      );
      final completed = _session(
        merchantId: 'm1',
        status: ActiveValidationStatus.completed,
        completedAt: DateTime.utc(2026, 1, 1),
      );
      expect(
        LoyaltyCelebrationDedupe.isLiveTerminalTransition(
          previous: awaiting,
          session: completed,
        ),
        isTrue,
      );
    });

    test('false for completed → completed', () {
      final completed = _session(
        merchantId: 'm1',
        status: ActiveValidationStatus.completed,
        completedAt: DateTime.utc(2026, 1, 1),
      );
      expect(
        LoyaltyCelebrationDedupe.isLiveTerminalTransition(
          previous: completed,
          session: completed,
        ),
        isFalse,
      );
    });
  });

  group('LoyaltyCelebrationDedupe.decideCompleted', () {
    final awaiting = _session(
      merchantId: 'm1',
      status: ActiveValidationStatus.awaiting,
    );
    final completed = _session(
      merchantId: 'm1',
      status: ActiveValidationStatus.completed,
      completedAt: DateTime.utc(2026, 10, 28),
    );
    final key = LoyaltyCelebrationDedupe.sessionKey(completed);

    test('prefs not ready → defer (no celebrate)', () {
      expect(
        LoyaltyCelebrationDedupe.decideCompleted(
          prefsReady: false,
          previous: awaiting,
          session: completed,
          seenKeys: <String>{},
        ),
        CelebrationDecision.defer,
      );
    });

    test('first snapshot already completed → markSeenOnly', () {
      expect(
        LoyaltyCelebrationDedupe.decideCompleted(
          prefsReady: true,
          previous: null,
          session: completed,
          seenKeys: <String>{},
        ),
        CelebrationDecision.markSeenOnly,
      );
    });

    test('awaiting → completed after ready → celebrate', () {
      expect(
        LoyaltyCelebrationDedupe.decideCompleted(
          prefsReady: true,
          previous: awaiting,
          session: completed,
          seenKeys: <String>{},
        ),
        CelebrationDecision.celebrate,
      );
    });

    test('same completed again (seen) → skipAlreadySeen', () {
      expect(
        LoyaltyCelebrationDedupe.decideCompleted(
          prefsReady: true,
          previous: awaiting,
          session: completed,
          seenKeys: <String>{key},
        ),
        CelebrationDecision.skipAlreadySeen,
      );
    });

    test('two merchants: celebrating B does not skip unseen A transition', () {
      final completedA = _session(
        merchantId: 'mA',
        status: ActiveValidationStatus.completed,
        completedAt: DateTime.utc(2026, 1, 1),
      );
      final awaitingA = _session(
        merchantId: 'mA',
        status: ActiveValidationStatus.awaiting,
      );
      final seenB = LoyaltyCelebrationDedupe.sessionKey(
        _session(
          merchantId: 'mB',
          status: ActiveValidationStatus.completed,
          completedAt: DateTime.utc(2026, 2, 1),
        ),
      );
      expect(
        LoyaltyCelebrationDedupe.decideCompleted(
          prefsReady: true,
          previous: awaitingA,
          session: completedA,
          seenKeys: <String>{seenB},
        ),
        CelebrationDecision.celebrate,
      );
    });
  });

  group('LoyaltyCelebrationDedupe.decideCancelled', () {
    final awaiting = _session(
      merchantId: 'm1',
      status: ActiveValidationStatus.awaiting,
    );
    final cancelled = _session(
      merchantId: 'm1',
      status: ActiveValidationStatus.cancelled,
      completedAt: DateTime.utc(2026, 10, 28),
    );

    test('cold first snapshot cancelled → markSeenOnly (no snackbar)', () {
      expect(
        LoyaltyCelebrationDedupe.decideCancelled(
          prefsReady: true,
          previous: null,
          session: cancelled,
          cancelledNotified: <String>{},
        ),
        CelebrationDecision.markSeenOnly,
      );
    });

    test('live awaiting → cancelled → celebrate', () {
      expect(
        LoyaltyCelebrationDedupe.decideCancelled(
          prefsReady: true,
          previous: awaiting,
          session: cancelled,
          cancelledNotified: <String>{},
        ),
        CelebrationDecision.celebrate,
      );
    });
  });
}
