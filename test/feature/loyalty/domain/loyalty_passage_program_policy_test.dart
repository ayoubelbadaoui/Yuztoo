import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/active_validation_request.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/loyalty_passage_program_policy.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

const _merchant = Merchant(
  id: 'm1',
  ownerUid: 'o1',
  name: 'Shop',
  email: 'a@b.c',
  phone: '+33600000000',
  city: 'Paris',
  loyaltyEnabled: true,
  loyaltyProgram: LoyaltyProgramConfig(
    programEnabled: true,
    passageValidation: LoyaltyPassageValidation.automatic,
    triggerType: LoyaltyTriggerType.purchaseTotal,
    cumulativeSpendRequiredEuros: 500,
  ),
);

void main() {
  group('isAutomaticPassageAllowedForMerchant', () {
    test('false when manual validation mode', () {
      const manual = Merchant(
        id: 'm1',
        ownerUid: 'o1',
        name: 'Shop',
        email: 'a@b.c',
        phone: '+33600000000',
        city: 'Paris',
        loyaltyEnabled: true,
        loyaltyProgram: LoyaltyProgramConfig(
          programEnabled: true,
          passageValidation: LoyaltyPassageValidation.manual,
        ),
      );
      expect(isAutomaticPassageAllowedForMerchant(manual), isFalse);
      expect(isVitrinePassageRequestAllowedForMerchant(manual), isTrue);
    });

    test('legacy alias still resolves to the same answer', () {
      const auto = Merchant(
        id: 'm1',
        ownerUid: 'o1',
        name: 'Shop',
        email: 'a@b.c',
        phone: '+33600000000',
        city: 'Paris',
        loyaltyEnabled: true,
        loyaltyProgram: LoyaltyProgramConfig(
          programEnabled: true,
          passageValidation: LoyaltyPassageValidation.automatic,
        ),
      );
      // ignore: deprecated_member_use_from_same_package
      expect(isBlePassageAllowedForMerchant(auto),
          isAutomaticPassageAllowedForMerchant(auto));
    });

    test('rappels toggle overrides stale manual loyalty_program', () {
      const desynced = Merchant(
        id: 'm1',
        ownerUid: 'o1',
        name: 'Shop',
        email: 'a@b.c',
        phone: '+33600000000',
        city: 'Paris',
        loyaltyEnabled: true,
        rappelsAutoPassageValidation: true,
        loyaltyProgram: LoyaltyProgramConfig(
          programEnabled: true,
          passageValidation: LoyaltyPassageValidation.manual,
        ),
      );
      expect(isAutomaticPassageAllowedForMerchant(desynced), isTrue);
      expect(isVitrinePassageRequestAllowedForMerchant(desynced), isFalse);
    });

    test('rappels toggle off forces manual even if program says automatic', () {
      const manualToggle = Merchant(
        id: 'm1',
        ownerUid: 'o1',
        name: 'Shop',
        email: 'a@b.c',
        phone: '+33600000000',
        city: 'Paris',
        loyaltyEnabled: true,
        rappelsAutoPassageValidation: false,
        loyaltyProgram: LoyaltyProgramConfig(
          programEnabled: true,
          passageValidation: LoyaltyPassageValidation.automatic,
        ),
      );
      expect(isAutomaticPassageAllowedForMerchant(manualToggle), isFalse);
      expect(isVitrinePassageRequestAllowedForMerchant(manualToggle), isTrue);
    });
  });

  group('resolveLoyaltyProgramForPassage', () {
    test('uses enrolled program when present', () {
      const enrolled = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        visitsRequired: 10,
      );
      const session = ActiveValidationRequest(
        merchantId: 'm1',
        clientUid: 'c1',
        clientDisplayName: 'A',
        status: ActiveValidationStatus.awaiting,
        programSnapshot: LoyaltyProgramConfig(
          programEnabled: true,
          triggerType: LoyaltyTriggerType.purchaseTotal,
        ),
      );
      final resolved = resolveLoyaltyProgramForPassage(
        merchant: _merchant,
        session: session,
        clientProgress: const ClientMerchantLoyaltyProgress(
          validatedPassages: 3,
          cumulativeSpendEuros: 0,
          enrolledProgram: enrolled,
        ),
      );
      expect(resolved.triggerType, LoyaltyTriggerType.visitCount);
    });

    test('uses session snapshot when not enrolled', () {
      const snapshot = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        visitsRequired: 8,
      );
      const session = ActiveValidationRequest(
        merchantId: 'm1',
        clientUid: 'c1',
        clientDisplayName: 'A',
        status: ActiveValidationStatus.awaiting,
        programSnapshot: snapshot,
      );
      final resolved = resolveLoyaltyProgramForPassage(
        merchant: _merchant,
        session: session,
        clientProgress: const ClientMerchantLoyaltyProgress(
          validatedPassages: 0,
          cumulativeSpendEuros: 0,
        ),
      );
      expect(resolved.visitsRequired, 8);
    });
  });

  group('merchantPassageCooldownEnabled', () {
    test('defaults to true when field is null', () {
      expect(merchantPassageCooldownEnabled(_merchant), isTrue);
    });

    test('false when merchant disabled cooldown', () {
      const off = Merchant(
        id: 'm1',
        ownerUid: 'o1',
        name: 'Shop',
        email: 'a@b.c',
        phone: '+33600000000',
        city: 'Paris',
        passageCooldownEnabled: false,
      );
      expect(merchantPassageCooldownEnabled(off), isFalse);
    });
  });
}
