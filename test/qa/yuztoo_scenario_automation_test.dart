import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/client_list/domain/entities/merchant_client_row.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/active_validation_request.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/failures/passage_cooldown_failure.dart';
import 'package:flutter_yuztoo/feature/loyalty/domain/loyalty_passage_program_policy.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant_subscription_plan.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/notification_quota_policy.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/auto_notification_triggers.dart';

/// Automated slice of `docs/qa/YUZTOO-500-*-SCENARIOS.md`.
///
/// Covers pure domain / policy logic that does not need a device, Firebase
/// emulator, or BLE radio. Scenario IDs in comments map to the markdown packs.
void main() {
  group('QA automation — loyalty policy matrix (adversarial TX)', () {
    Merchant merchant({
      required LoyaltyPassageValidation mode,
      required LoyaltyTriggerType trigger,
      required LoyaltyRewardKind reward,
      bool loyaltyEnabled = true,
      bool programEnabled = true,
      bool? rappelsAuto,
    }) {
      return Merchant(
        id: 'm1',
        ownerUid: 'o1',
        name: 'Shop',
        email: 'a@b.c',
        phone: '+33600000000',
        city: 'Paris',
        loyaltyEnabled: loyaltyEnabled,
        rappelsAutoPassageValidation: rappelsAuto,
        loyaltyProgram: LoyaltyProgramConfig(
          programEnabled: programEnabled,
          passageValidation: mode,
          triggerType: trigger,
          rewardKind: reward,
          visitsRequired: 10,
          cumulativeSpendRequiredEuros: 100,
        ),
      );
    }

    ActiveValidationRequest session({
      required LoyaltyProgramConfig snapshot,
      required ActiveValidationSource source,
      DateTime? createdAt,
      DateTime? merchantBleConnectedAt,
    }) {
      return ActiveValidationRequest(
        merchantId: 'm1',
        clientUid: 'c1',
        clientDisplayName: 'Client',
        status: ActiveValidationStatus.awaiting,
        programSnapshot: snapshot,
        source: source,
        createdAt: createdAt ?? DateTime.now(),
        merchantBleConnectedAt: merchantBleConnectedAt,
      );
    }

    test('full mode×trigger×reward×source auto-confirm matrix', () {
      var cases = 0;
      for (final mode in LoyaltyPassageValidation.values) {
        for (final trigger in LoyaltyTriggerType.values) {
          for (final reward in LoyaltyRewardKind.values) {
            for (final source in ActiveValidationSource.values) {
              final m = merchant(mode: mode, trigger: trigger, reward: reward);
              final snap = m.loyaltyProgram!;
              final s = session(snapshot: snap, source: source);

              final mustAmount = loyaltyProgramRequiresSpendAmount(snap);
              final expectAuto = mode == LoyaltyPassageValidation.automatic &&
                  source != ActiveValidationSource.ble &&
                  !mustAmount;

              expect(
                isPassageSessionAutoConfirmed(merchant: m, session: s),
                expectAuto,
                reason:
                    'mode=$mode trigger=$trigger reward=$reward source=$source',
              );

              // Vitrine requests only in manual mode when loyalty active.
              expect(
                isVitrinePassageRequestAllowedForMerchant(m),
                mode == LoyaltyPassageValidation.manual,
                reason: 'vitrine mode=$mode',
              );

              // Scans always open a session while loyalty is on.
              expect(isScanPassageSessionAllowedForMerchant(m), isTrue);

              cases++;
            }
          }
        }
      }
      // 2 modes × 2 triggers × 4 rewards × 2 sources = 32
      expect(cases, 32);
    });

    test('TX: BLE never auto-confirms even in automatic visitCount', () {
      final m = merchant(
        mode: LoyaltyPassageValidation.automatic,
        trigger: LoyaltyTriggerType.visitCount,
        reward: LoyaltyRewardKind.discountPercent,
      );
      final s = session(
        snapshot: m.loyaltyProgram!,
        source: ActiveValidationSource.ble,
      );
      expect(isPassageSessionAutoConfirmed(merchant: m, session: s), isFalse);
    });

    test('TX: enrolled snapshot beats live spend program for auto-confirm', () {
      final live = merchant(
        mode: LoyaltyPassageValidation.automatic,
        trigger: LoyaltyTriggerType.visitCount,
        reward: LoyaltyRewardKind.discountPercent,
      );
      const enrolled = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.purchaseTotal,
        cumulativeSpendRequiredEuros: 500,
      );
      final s = session(
        snapshot: live.loyaltyProgram!,
        source: ActiveValidationSource.vitrine,
      );
      expect(
        isPassageSessionAutoConfirmed(
          merchant: live,
          session: s,
          clientProgress: const ClientMerchantLoyaltyProgress(
            validatedPassages: 2,
            cumulativeSpendEuros: 10,
            enrolledProgram: enrolled,
          ),
        ),
        isFalse,
      );
      expect(
        resolveLoyaltyProgramForPassage(
          merchant: live,
          session: s,
          clientProgress: const ClientMerchantLoyaltyProgress(
            validatedPassages: 2,
            cumulativeSpendEuros: 10,
            enrolledProgram: enrolled,
          ),
        ).triggerType,
        LoyaltyTriggerType.purchaseTotal,
      );
    });

    test('TX: loyalty disabled kills scan + auto + vitrine', () {
      final m = merchant(
        mode: LoyaltyPassageValidation.automatic,
        trigger: LoyaltyTriggerType.visitCount,
        reward: LoyaltyRewardKind.discountPercent,
        loyaltyEnabled: false,
      );
      expect(isMerchantLoyaltyPassageActive(m), isFalse);
      expect(isScanPassageSessionAllowedForMerchant(m), isFalse);
      expect(isAutomaticPassageAllowedForMerchant(m), isFalse);
      expect(isVitrinePassageRequestAllowedForMerchant(m), isFalse);
    });

    test('TX: programEnabled false kills loyalty passage', () {
      final m = merchant(
        mode: LoyaltyPassageValidation.automatic,
        trigger: LoyaltyTriggerType.visitCount,
        reward: LoyaltyRewardKind.discountPercent,
        programEnabled: false,
      );
      expect(isMerchantLoyaltyPassageActive(m), isFalse);
      expect(isScanPassageSessionAllowedForMerchant(m), isFalse);
    });

    test('TX: rappels toggle overrides stale loyalty_program mode', () {
      final forcedAuto = merchant(
        mode: LoyaltyPassageValidation.manual,
        trigger: LoyaltyTriggerType.visitCount,
        reward: LoyaltyRewardKind.discountPercent,
        rappelsAuto: true,
      );
      expect(isAutomaticPassageAllowedForMerchant(forcedAuto), isTrue);
      expect(isVitrinePassageRequestAllowedForMerchant(forcedAuto), isFalse);

      final forcedManual = merchant(
        mode: LoyaltyPassageValidation.automatic,
        trigger: LoyaltyTriggerType.visitCount,
        reward: LoyaltyRewardKind.discountPercent,
        rappelsAuto: false,
      );
      expect(isAutomaticPassageAllowedForMerchant(forcedManual), isFalse);
      expect(isVitrinePassageRequestAllowedForMerchant(forcedManual), isTrue);
    });

    test('TX: points reward requires amount (blocks auto-confirm)', () {
      final m = merchant(
        mode: LoyaltyPassageValidation.automatic,
        trigger: LoyaltyTriggerType.visitCount,
        reward: LoyaltyRewardKind.loyaltyPoints,
      );
      expect(loyaltyProgramRequiresSpendAmount(m.loyaltyProgram!), isTrue);
      expect(
        isPassageSessionAutoConfirmed(
          merchant: m,
          session: session(
            snapshot: m.loyaltyProgram!,
            source: ActiveValidationSource.vitrine,
          ),
        ),
        isFalse,
      );
    });

    test('TX: session programSnapshot used when not enrolled', () {
      final live = merchant(
        mode: LoyaltyPassageValidation.automatic,
        trigger: LoyaltyTriggerType.purchaseTotal,
        reward: LoyaltyRewardKind.purchaseVoucher,
      );
      const frozen = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        visitsRequired: 7,
      );
      final resolved = resolveLoyaltyProgramForPassage(
        merchant: live,
        session: session(
          snapshot: frozen,
          source: ActiveValidationSource.vitrine,
        ),
      );
      expect(resolved.visitsRequired, 7);
      expect(resolved.triggerType, LoyaltyTriggerType.visitCount);
    });
  });

  group('QA automation — session expiry / BLE connected flags', () {
    test('TX: awaiting older than 15 minutes isExpired', () {
      final session = ActiveValidationRequest(
        merchantId: 'm1',
        clientUid: 'c1',
        clientDisplayName: 'A',
        status: ActiveValidationStatus.awaiting,
        programSnapshot: const LoyaltyProgramConfig(programEnabled: true),
        createdAt: DateTime.now().subtract(const Duration(minutes: 16)),
      );
      expect(session.isExpired, isTrue);
      expect(session.isAwaiting, isTrue);
    });

    test('TX: awaiting at 14 minutes is not expired', () {
      final session = ActiveValidationRequest(
        merchantId: 'm1',
        clientUid: 'c1',
        clientDisplayName: 'A',
        status: ActiveValidationStatus.awaiting,
        programSnapshot: const LoyaltyProgramConfig(programEnabled: true),
        createdAt: DateTime.now().subtract(const Duration(minutes: 14)),
      );
      expect(session.isExpired, isFalse);
    });

    test('TX: completed session never expired via isExpired helper', () {
      final session = ActiveValidationRequest(
        merchantId: 'm1',
        clientUid: 'c1',
        clientDisplayName: 'A',
        status: ActiveValidationStatus.completed,
        programSnapshot: const LoyaltyProgramConfig(programEnabled: true),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(session.isExpired, isFalse);
    });

    test('TX: isMerchantBleConnected requires timestamp', () {
      const disconnected = ActiveValidationRequest(
        merchantId: 'm1',
        clientUid: 'c1',
        clientDisplayName: 'A',
        status: ActiveValidationStatus.awaiting,
        programSnapshot: LoyaltyProgramConfig(programEnabled: true),
        source: ActiveValidationSource.ble,
      );
      expect(disconnected.isBle, isTrue);
      expect(disconnected.isMerchantBleConnected, isFalse);

      final connected = ActiveValidationRequest(
        merchantId: 'm1',
        clientUid: 'c1',
        clientDisplayName: 'A',
        status: ActiveValidationStatus.awaiting,
        programSnapshot: const LoyaltyProgramConfig(programEnabled: true),
        source: ActiveValidationSource.ble,
        merchantBleConnectedAt: DateTime.now(),
      );
      expect(connected.isMerchantBleConnected, isTrue);
    });

    test('TX: unknown Firestore status/source parse safely', () {
      final parsed = ActiveValidationRequest.fromFirestoreMap(
        merchantId: 'm1',
        clientUid: 'c1',
        data: <String, dynamic>{
          'client_display_name': 'A',
          'status': 'DONE',
          'source': 'telepathy',
          'program_snapshot': <String, dynamic>{
            'program_enabled': true,
          },
        },
      );
      expect(parsed.status, ActiveValidationStatus.awaiting);
      expect(parsed.source, ActiveValidationSource.vitrine);
    });
  });

  group('QA automation — cooldown copy / defaults', () {
    test('TX: PassageCooldownFailure French canonical message', () {
      const f = PassageCooldownFailure();
      expect(
        f.message,
        contains('Patientez 1 heure'),
      );
    });

    test('TX: cooldown defaults enabled when null', () {
      const m = Merchant(
        id: 'm1',
        ownerUid: 'o1',
        name: 'Shop',
        email: 'a@b.c',
        phone: '+33600000000',
        city: 'Paris',
      );
      expect(merchantPassageCooldownEnabled(m), isTrue);
    });
  });

  group('QA automation — auto notification triggers', () {
    test('T/TX: visitDetected in labels but not selectable / not wired', () {
      expect(
        AutoNotificationTriggers.triggerLabels,
        contains(AutoNotificationTriggers.visitDetected),
      );
      expect(
        AutoNotificationTriggers.selectableTriggerLabels,
        isNot(contains(AutoNotificationTriggers.visitDetected)),
      );
      expect(
        AutoNotificationTriggers.isWiredInCloud(
          AutoNotificationTriggers.visitDetected,
        ),
        isFalse,
      );
    });

    test('T/TX: every selectable trigger is cloud-wired', () {
      for (final t in AutoNotificationTriggers.selectableTriggerLabels) {
        expect(AutoNotificationTriggers.isWiredInCloud(t), isTrue, reason: t);
      }
    });

    test('wired set size is 10 (excludes visitDetected)', () {
      expect(AutoNotificationTriggers.wiredInCloud.length, 10);
      expect(AutoNotificationTriggers.selectableTriggerLabels.length, 10);
    });
  });

  group('QA automation — notification quota boundaries', () {
    final recent = DateTime.now().subtract(const Duration(days: 1));
    final exactly7d = DateTime.now().subtract(const Duration(days: 7));
    final expired = DateTime.now().subtract(const Duration(days: 8));

    test('launch flag off ⇒ free plan unlimited', () {
      expect(kFreePlanWeeklyNotificationQuotaEnabled, isFalse);
      expect(
        canSendManualNotification(
          plan: MerchantSubscriptionPlan.gratuit,
          sentCount: 99,
          resetAt: recent,
        ),
        isTrue,
      );
    });

    test('TX: when quota enabled, 5/5 blocks free plan', () {
      expect(
        canSendManualNotification(
          plan: MerchantSubscriptionPlan.gratuit,
          sentCount: 5,
          resetAt: recent,
          quotaEnabled: true,
        ),
        isFalse,
      );
    });

    test('TX: window at >=7 days frees quota', () {
      expect(
        notificationsSentInWindow(sentCount: 5, resetAt: exactly7d),
        0,
      );
      expect(
        canSendManualNotification(
          plan: MerchantSubscriptionPlan.gratuit,
          sentCount: 5,
          resetAt: exactly7d,
          quotaEnabled: true,
        ),
        isTrue,
      );
      expect(
        canSendManualNotification(
          plan: MerchantSubscriptionPlan.gratuit,
          sentCount: 5,
          resetAt: expired,
          quotaEnabled: true,
        ),
        isTrue,
      );
    });

    test('paid plans ignore quota even when enabled', () {
      for (final plan in [
        MerchantSubscriptionPlan.essentiel,
        MerchantSubscriptionPlan.premium,
      ]) {
        expect(
          canSendManualNotification(
            plan: plan,
            sentCount: 500,
            resetAt: recent,
            quotaEnabled: true,
          ),
          isTrue,
        );
      }
    });
  });

  group('QA automation — CRM segment edges', () {
    test('manual_segment overrides auto VIP computation', () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        validatedPassages: 0,
        lastVisitAt: DateTime.now(),
        manualSegment: ClientSegment.vip,
      );
      expect(row.segment, ClientSegment.vip);
      expect(row.autoSegment, ClientSegment.nouveau);
    });

    test('inactif when daysSince > 60 even with high passages', () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        validatedPassages: 25,
        lastVisitAt: DateTime.now().subtract(const Duration(days: 61)),
      );
      expect(row.segment, ClientSegment.inactif);
    });

    test('heartLevel does not drive segment', () {
      final row = MerchantClientRow(
        clientUid: 'u1',
        heartLevel: 3,
        validatedPassages: 0,
        followedAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(row.segment, ClientSegment.nouveau);
    });

    test('displayLabel never leaks uid', () {
      const row = MerchantClientRow(clientUid: 'super-secret-uid');
      expect(row.displayLabel, 'Client');
      expect(row.displayLabel, isNot(contains('super-secret')));
    });
  });

  group('QA automation — loyalty points / amount helpers', () {
    test('effectiveAskClientPurchaseAmount = must OR optional', () {
      const must = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.purchaseTotal,
      );
      expect(must.clientMustEnterPurchaseAmount, isTrue);
      expect(must.effectiveAskClientPurchaseAmount, isTrue);

      const optionalOnly = LoyaltyProgramConfig(
        programEnabled: true,
        triggerType: LoyaltyTriggerType.visitCount,
        optionalAskClientPurchaseAmount: true,
      );
      expect(optionalOnly.clientMustEnterPurchaseAmount, isFalse);
      expect(optionalOnly.effectiveAskClientPurchaseAmount, isTrue);
    });
  });
}
