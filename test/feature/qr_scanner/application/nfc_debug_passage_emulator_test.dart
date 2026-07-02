import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/loyalty/application/use_cases/process_vitrine_scan_visit.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/qr_scanner/application/nfc_debug_passage_emulator.dart';

void main() {
  group('NfcDebugPassageEmulator.resultSummary', () {
    test('maps ScanVisitResult variants to French summaries', () {
      expect(
        NfcDebugPassageEmulator.resultSummary(const ScanVisitGuest()),
        contains('Invité'),
      );
      expect(
        NfcDebugPassageEmulator.resultSummary(
          const ScanVisitVisitRecorded(
            ClientMerchantLoyaltyProgress(
              validatedPassages: 3,
              cumulativeSpendEuros: 0,
            ),
          ),
        ),
        contains('3 passage'),
      );
      expect(
        NfcDebugPassageEmulator.resultSummary(
          const ScanVisitAwaitingMerchant(),
        ),
        contains('validation commerçant'),
      );
    });
  });
}
