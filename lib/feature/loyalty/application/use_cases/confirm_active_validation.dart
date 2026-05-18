import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../client_notification/domain/repositories/client_notification_repository.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/entities/active_validation_request.dart';
import '../../domain/entities/client_merchant_loyalty_progress.dart';
import '../../domain/repositories/client_loyalty_repository.dart';
import '../loyalty_passage_notification_helper.dart';

/// Merchant-side: applies the loyalty deltas AND closes the active_validation
/// session in a single Firestore transaction. The deltas are computed from
/// the **merchant's current loyalty program** — not from the
/// `session.programSnapshot` — so a tampered snapshot can't grandfather the
/// client into a more favourable program. The snapshot is informational only
/// (it's what drives the form rendering on the merchant side so the merchant
/// sees what the client saw at request time).
///
/// Atomicity: the in-transaction guard in `applyPassageDeltas` reads the
/// session doc and rejects if it's not 'awaiting'. That means a second tap
/// on "Valider" (whether from a re-fired listener or a stale popup) hits a
/// 'completed' session and bails out cleanly — no double counter increment,
/// no orphaned 'awaiting' doc.
class ConfirmActiveValidation {
  ConfirmActiveValidation(
    this._loyaltyRepo,
    this._notificationRepo,
  );

  final ClientLoyaltyRepository _loyaltyRepo;
  final ClientNotificationRepository _notificationRepo;

  Future<Result<ClientMerchantLoyaltyProgress>> call({
    required String actingOwnerUid,
    required Merchant merchant,
    required ActiveValidationRequest session,
    double? declaredSpendEuros,
  }) async {
    if (actingOwnerUid.isEmpty || session.clientUid.isEmpty) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Action non autorisée'),
      );
    }
    if (merchant.ownerUid != actingOwnerUid) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message: 'Vous n\'êtes pas propriétaire de ce commerce',
        ),
      );
    }
    if (merchant.id != session.merchantId) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Session liée à un autre commerce'),
      );
    }

    // The MERCHANT's CURRENT config is the source of truth for the database
    // write. The session's program_snapshot is taken at request time and is
    // used only to render the form so the merchant sees what the client saw.
    // Using merchant.loyaltyProgram (live) here prevents a tampered client
    // snapshot from forging favourable terms on first-visit enrollment.
    final LoyaltyProgramConfig config = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: true);
    if (!config.programEnabled) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Programme de fidélité désactivé'),
      );
    }

    final bool spendRequired =
        config.triggerType == LoyaltyTriggerType.purchaseTotal ||
            config.rewardKind == LoyaltyRewardKind.loyaltyPoints;
    final double spend = declaredSpendEuros ?? 0;

    if (spendRequired && spend <= 0) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message: 'Indiquez le montant d\'achat à prendre en compte (€)',
        ),
      );
    }
    if (spend > 0 &&
        config.minimumPerVisitEnabled &&
        config.minimumPerVisitEuros != null &&
        config.minimumPerVisitEuros! > 0 &&
        spend < config.minimumPerVisitEuros!) {
      return Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message:
              'Montant inférieur au minimum par passage (${config.minimumPerVisitEuros} €)',
        ),
      );
    }

    final int validatedDelta =
        config.triggerType == LoyaltyTriggerType.visitCount ? 1 : 0;
    final double spendDelta = spend > 0 ? spend : 0;

    // ONE transaction does both: loyalty_clients counters AND
    // active_validations status flip. If the session doc was already
    // 'completed' (double-tap), this throws before any write lands.
    final result = await _loyaltyRepo.applyPassageDeltas(
      merchantId: merchant.id,
      clientUid: session.clientUid,
      validatedPassagesDelta: validatedDelta,
      cumulativeSpendEurosDelta: spendDelta,
      enrollProgram: config,
      completeActiveValidation: ActiveValidationCompletion(
        validatedDelta: validatedDelta,
        spendDelta: spendDelta,
        declaredSpendEuros: spend > 0 ? spend : null,
      ),
    );

    return result.fold(
      (failure) async => Left<AppFailure, ClientMerchantLoyaltyProgress>(
        failure,
      ),
      (progress) async {
        // Notification is best-effort — the client already sees the
        // celebration via the session listener, so a notification failure
        // doesn't break the user-visible flow.
        await writePassageValidatedNotification(
          repository: _notificationRepo,
          clientUid: session.clientUid,
          merchant: merchant,
          config: config,
          progressAfter: progress,
          validatedSpendEuros: spend > 0 ? spend : null,
        );
        return Right<AppFailure, ClientMerchantLoyaltyProgress>(progress);
      },
    );
  }
}
