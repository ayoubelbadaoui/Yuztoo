import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';

void main() {
  group('ClientMerchantLoyaltyProgress', () {
    test('empty() produces zero values', () {
      const p = ClientMerchantLoyaltyProgress.empty();
      expect(p.validatedPassages, 0);
      expect(p.cumulativeSpendEuros, 0.0);
    });

    test('equality — two identical instances are equal (Equatable)', () {
      const a = ClientMerchantLoyaltyProgress(
        validatedPassages: 3,
        cumulativeSpendEuros: 45.0,
      );
      const b = ClientMerchantLoyaltyProgress(
        validatedPassages: 3,
        cumulativeSpendEuros: 45.0,
      );
      expect(a, b);
    });

    test('inequality — different validatedPassages', () {
      const a = ClientMerchantLoyaltyProgress(
        validatedPassages: 2,
        cumulativeSpendEuros: 0,
      );
      const b = ClientMerchantLoyaltyProgress(
        validatedPassages: 5,
        cumulativeSpendEuros: 0,
      );
      expect(a, isNot(b));
    });

    test('props contains all fields including enrollment', () {
      const p = ClientMerchantLoyaltyProgress(
        validatedPassages: 1,
        cumulativeSpendEuros: 33.5,
      );
      expect(p.props, [1, 33.5, false, false, false, null, null]);
    });

    test('welcomeBonClaimed defaults to false and surfaces in equality', () {
      const a = ClientMerchantLoyaltyProgress(
        validatedPassages: 1,
        cumulativeSpendEuros: 0,
      );
      const b = ClientMerchantLoyaltyProgress(
        validatedPassages: 1,
        cumulativeSpendEuros: 0,
        welcomeBonClaimed: true,
      );
      expect(a.welcomeBonClaimed, isFalse);
      expect(a, isNot(b),
          reason: 'two progresses with different claimed flag must differ');
    });
  });
}
