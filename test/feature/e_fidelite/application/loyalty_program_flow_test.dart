import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/e_fidelite/application/loyalty_program_flow.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';

Merchant _merchant({
  LoyaltyProgramConfig? loyaltyProgram,
  bool loyaltyEnabled = false,
}) {
  return Merchant(
    id: 'm1',
    ownerUid: 'u1',
    name: 'Shop',
    email: 'a@b.c',
    phone: '+33600000000',
    city: 'Paris',
    loyaltyEnabled: loyaltyEnabled,
    loyaltyProgram: loyaltyProgram,
  );
}

void main() {
  group('resolveEFideliteInitialMode', () {
    test('wizard when pending configuration', () {
      final merchant = _merchant(
        loyaltyProgram: const LoyaltyProgramConfig(programEnabled: true),
      );
      expect(
        resolveEFideliteInitialMode(
          merchant: merchant,
          pendingConfiguration: true,
        ),
        EFideliteInitialMode.wizard,
      );
    });

    test('wizard when no saved program', () {
      expect(
        resolveEFideliteInitialMode(
          merchant: _merchant(),
          pendingConfiguration: false,
        ),
        EFideliteInitialMode.wizard,
      );
    });

    test('recap when saved program exists', () {
      expect(
        resolveEFideliteInitialMode(
          merchant: _merchant(
            loyaltyProgram: const LoyaltyProgramConfig(programEnabled: true),
          ),
          pendingConfiguration: false,
        ),
        EFideliteInitialMode.recap,
      );
    });

    test('recap when saved but disabled', () {
      expect(
        resolveEFideliteInitialMode(
          merchant: _merchant(
            loyaltyProgram: const LoyaltyProgramConfig(programEnabled: false),
          ),
          pendingConfiguration: false,
        ),
        EFideliteInitialMode.recap,
      );
    });
  });

  group('loyaltyWizardSaveEnabled', () {
    const config = LoyaltyProgramConfig(programEnabled: true);

    test('disabled when enabling without completing wizard', () {
      expect(
        loyaltyWizardSaveEnabled(
          config: config,
          hasSavedLoyaltyProgram: false,
          editingFromRecap: false,
          maxStepVisited: 0,
        ),
        isFalse,
      );
    });

    test('enabled after last step visited', () {
      expect(
        loyaltyWizardSaveEnabled(
          config: config,
          hasSavedLoyaltyProgram: false,
          editingFromRecap: false,
          maxStepVisited: loyaltyWizardLastStepIndex,
        ),
        isTrue,
      );
    });

    test('enabled when editing from recap', () {
      expect(
        loyaltyWizardSaveEnabled(
          config: config,
          hasSavedLoyaltyProgram: true,
          editingFromRecap: true,
          maxStepVisited: 0,
        ),
        isTrue,
      );
    });

    test('enabled when disabling program', () {
      expect(
        loyaltyWizardSaveEnabled(
          config: const LoyaltyProgramConfig(programEnabled: false),
          hasSavedLoyaltyProgram: false,
          editingFromRecap: false,
          maxStepVisited: 0,
        ),
        isTrue,
      );
    });
  });
}
