import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../client_notification/domain/repositories/client_notification_repository.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/entities/client_merchant_loyalty_progress.dart';
import '../../domain/loyalty_passage_program_policy.dart';
import '../../domain/repositories/client_loyalty_repository.dart';
import '../loyalty_passage_notification_helper.dart';

/// Enregistre un passage validé côté client lors d'un scan en mode
/// **automatique** (NFC, QR, deep-link) — sans confirmation du commerçant.
///
/// Incrémente `validated_passages` sur `loyalty_clients` (paliers Nouveau /
/// Habitué / VIP + stats CRM). Quand la fidélité est active, le programme est
/// inscrit au premier passage (la carte fidélité apparaît côté client) et une
/// notification « Passage validé » est écrite — ce qui déclenche le push FCM
/// via [onNotificationCreated], exactement comme la validation manuelle.
///
/// [_notificationRepo] est optionnel pour rester compatible avec les contextes
/// (tests, passage seul sans fidélité) où aucune notification n'est attendue.
class RecordClientVisitPassage {
  const RecordClientVisitPassage(
    this._repository, [
    this._notificationRepo,
  ]);

  final ClientLoyaltyRepository _repository;
  final ClientNotificationRepository? _notificationRepo;

  Future<Result<ClientMerchantLoyaltyProgress>> call({
    required String clientUid,
    required Merchant merchant,
  }) async {
    if (clientUid.isEmpty) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Utilisateur non connecté'),
      );
    }

    final bool loyaltyActive = isMerchantLoyaltyPassageActive(merchant);
    final LoyaltyProgramConfig? config =
        loyaltyActive ? merchantLiveLoyaltyProgram(merchant) : null;

    final result = await _repository.applyPassageDeltas(
      merchantId: merchant.id,
      clientUid: clientUid,
      validatedPassagesDelta: 1,
      // Inscrit le programme au premier passage pour que la carte fidélité
      // s'affiche immédiatement côté client (parité avec le flux manuel).
      enrollProgram: config,
      enforcePassageCooldown: merchantPassageCooldownEnabled(merchant),
    );

    // Notification best-effort : un échec d'écriture ne doit pas casser le
    // passage déjà enregistré (le client voit aussi l'overlay de célébration).
    final notificationRepo = _notificationRepo;
    if (loyaltyActive && config != null && notificationRepo != null) {
      await result.fold(
        (_) async {},
        (progress) async {
          await writePassageValidatedNotification(
            repository: notificationRepo,
            clientUid: clientUid,
            merchant: merchant,
            config: config,
            progressAfter: progress,
          );
        },
      );
    }

    return result;
  }
}
