import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/core/infrastructure/nfc_service.dart';
import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/process_vitrine_scan_visit.dart';
import 'package:flutter_yuztoo/feature/qr_scanner/application/nfc_debug_scenarios.dart';

void main() {
  group('NfcDebugScenarioCatalog', () {
    test('tag read scenarios map to production French messages', () {
      final empty = NfcDebugScenarioCatalog.tagReadResult(
        NfcTagReadScenario.emptyTag,
      );
      expect(empty, isA<NfcError>());
      expect(
        (empty as NfcError).message,
        contains('badge NFC est vide'),
      );

      final invalid = NfcDebugScenarioCatalog.tagReadResult(
        NfcTagReadScenario.invalidTag,
      );
      expect((invalid as NfcError).message, contains('vitrine Yuztoo'));
    });

    test('tag write scenarios include success and locked tag', () {
      expect(
        NfcDebugScenarioCatalog.tagWriteResult(NfcTagWriteScenario.writeSuccess),
        isA<NfcSuccess>(),
      );
      final locked = NfcDebugScenarioCatalog.tagWriteResult(
        NfcTagWriteScenario.readOnly,
      );
      expect((locked as NfcError).message, contains('lecture seule'));
    });

    test('funnel scenarios cover all ScanVisitResult branches', () {
      for (final scenario in NfcVitrineFunnelScenario.values) {
        expect(
          NfcDebugScenarioCatalog.funnelResult(scenario),
          isA<ScanVisitResult>(),
        );
      }
      expect(
        NfcDebugScenarioCatalog.funnelResult(
          NfcVitrineFunnelScenario.guestConnectSheet,
        ),
        isA<ScanVisitGuest>(),
      );
      expect(
        NfcDebugScenarioCatalog.funnelResult(
          NfcVitrineFunnelScenario.cooldownSnackbar,
        ),
        isA<ScanVisitCooldownBlocked>(),
      );
    });

    test('option lists align with enum counts', () {
      expect(
        NfcDebugScenarioCatalog.tagReadOptions().length,
        NfcTagReadScenario.values.length,
      );
      expect(
        NfcDebugScenarioCatalog.tagWriteOptions().length,
        NfcTagWriteScenario.values.length,
      );
      expect(
        NfcDebugScenarioCatalog.funnelOptions().length,
        NfcVitrineFunnelScenario.values.length,
      );
    });
  });
}
