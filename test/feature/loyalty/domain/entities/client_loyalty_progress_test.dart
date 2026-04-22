import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';

void main() {
  group('ClientMerchantLoyaltyProgress', () {
    test('empty() produces zero values', () {
      const p = ClientMerchantLoyaltyProgress.empty();
      expect(p.validatedPassages, 0);
      expect(p.pendingPassages, 0);
      expect(p.cumulativeSpendEuros, 0.0);
    });

    test('equality — two identical instances are equal (Equatable)', () {
      const a = ClientMerchantLoyaltyProgress(
        validatedPassages: 3,
        pendingPassages: 1,
        cumulativeSpendEuros: 45.0,
      );
      const b = ClientMerchantLoyaltyProgress(
        validatedPassages: 3,
        pendingPassages: 1,
        cumulativeSpendEuros: 45.0,
      );
      expect(a, b);
    });

    test('inequality — different validatedPassages', () {
      const a = ClientMerchantLoyaltyProgress(
        validatedPassages: 2,
        pendingPassages: 0,
        cumulativeSpendEuros: 0,
      );
      const b = ClientMerchantLoyaltyProgress(
        validatedPassages: 5,
        pendingPassages: 0,
        cumulativeSpendEuros: 0,
      );
      expect(a, isNot(b));
    });

    test('props contains all three fields', () {
      const p = ClientMerchantLoyaltyProgress(
        validatedPassages: 1,
        pendingPassages: 2,
        cumulativeSpendEuros: 33.5,
      );
      expect(p.props, [1, 2, 33.5]);
    });
  });
}
