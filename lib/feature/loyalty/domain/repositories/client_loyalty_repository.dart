import '../../../../core/domain/core/result.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../entities/client_merchant_loyalty_progress.dart';
import '../entities/loyalty_pending_client_row.dart';

/// Optional payload: when set on [ClientLoyaltyRepository.applyPassageDeltas],
/// the loyalty_clients write AND the active_validation transition to
/// 'completed' happen inside the same Firestore transaction. This is the only
/// way to keep the two collections consistent — without it, a network flake
/// between the two writes would leave the counter incremented but the session
/// stuck at 'awaiting', causing the merchant queue listener to re-pop the
/// validation form.
class ActiveValidationCompletion {
  const ActiveValidationCompletion({
    required this.validatedDelta,
    required this.spendDelta,
    this.declaredSpendEuros,
  });

  final int validatedDelta;
  final double spendDelta;
  final double? declaredSpendEuros;
}

/// Persistance progression fidélité côté client.
abstract class ClientLoyaltyRepository {
  Stream<ClientMerchantLoyaltyProgress> watchProgress(
    String merchantId,
    String clientUid,
  );

  Future<ClientMerchantLoyaltyProgress> readProgress(
    String merchantId,
    String clientUid,
  );

  Future<Result<ClientMerchantLoyaltyProgress>> applyPassageDeltas({
    required String merchantId,
    required String clientUid,
    int validatedPassagesDelta = 0,
    double cumulativeSpendEurosDelta = 0,
    /// Snapshot current program on first enrollment (merchant first
    /// validation of this client).
    LoyaltyProgramConfig? enrollProgram,
    /// When set, also flips the matching `active_validations/{clientUid}`
    /// doc to status='completed' atomically with the loyalty_clients write.
    /// The transaction reads the session first and rejects if status is not
    /// 'awaiting' — that's the merchant-side double-validation guard.
    ActiveValidationCompletion? completeActiveValidation,
    /// When false, skips the 1 h anti double-scan cooldown for this write.
    bool enforcePassageCooldown = true,
  });

  /// Returns a real-time stream of loyalty clients whose progress meets or
  /// exceeds the reward threshold. The merchant uses this to see who has an
  /// available reward and trigger [redeemReward] when the physical reward is
  /// handed to the client.
  ///
  /// Implemented via a Dart-side filter on all loyalty_clients so that both
  /// [visitCount] and [purchaseTotal] trigger types are handled uniformly.
  Stream<List<LoyaltyPendingClientRow>> watchClientsWithRewardAvailable({
    required String merchantId,
    required int visitsRequired,
    required double spendRequiredEuros,
    required bool iSpendBased,
  });

  /// Marks a reward as used by deducting [visitsRequired] (or resetting spend)
  /// from the client's progress, starting a new reward cycle. Must be called
  /// by the merchant owner — client-side rules forbid negative deltas.
  Future<Result<ClientMerchantLoyaltyProgress>> redeemReward({
    required String merchantId,
    required String clientUid,
    required int visitsRequired,
    required double spendRequiredEuros,
    required bool isSpendBased,
  });

  /// Marks the welcome bon as claimed (used) at the given merchant.
  /// Idempotent: a second call after the bon is already claimed is a no-op
  /// success — never an error. Returns the updated progress (with
  /// `welcomeBonClaimed = true`).
  ///
  /// Preconditions enforced by the implementation:
  ///   - Merchant must have a welcome gift configured (checked in use case).
  ///   - Creates the loyalty_clients doc on first claim when missing.
  Future<Result<ClientMerchantLoyaltyProgress>> claimWelcomeBon({
    required String merchantId,
    required String clientUid,
  });

  /// Returns a map of `{clientUid: segment}` for all loyalty clients of a merchant.
  ///
  /// Canonical passage-based segment values (mirrors Cloud Functions `computeSegment`):
  ///   - `'vip'`      — validated_passages ≥ 10 AND last visit ≤ 60 days ago
  ///   - `'habitue'`  — validated_passages ≥ 3  AND last visit ≤ 60 days ago
  ///   - `'nouveau'`  — validated_passages < 3  AND last visit ≤ 60 days ago
  ///   - `'inactif'`  — last visit > 60 days ago (regardless of passages)
  ///
  /// Followers NOT in the loyalty_clients subcollection default to `'nouveau'`
  /// in send_merchant_notification (no loyalty doc = no visits yet).
  ///
  /// When the merchant sets `merchants/{merchantId}/clients/{uid}.manual_segment`,
  /// that value overrides the passage-based segment for ciblage.
  Future<Map<String, String>> getClientSegments(String merchantId);
}
