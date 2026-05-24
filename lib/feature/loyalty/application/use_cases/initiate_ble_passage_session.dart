import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../auth/core/domain/entities/auth_user.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/failures/ble_passage_failure.dart';
import '../../domain/loyalty_passage_program_policy.dart';
import '../../domain/repositories/active_validation_repository.dart';
import 'ensure_client_follows_merchant.dart';

/// Client BLE: follow gate + create `active_validations` session with BLE metadata.
class InitiateBlePassageSession {
  InitiateBlePassageSession(
    this._validationRepo,
    this._ensureFollow,
  );

  final ActiveValidationRepository _validationRepo;
  final EnsureClientFollowsMerchant _ensureFollow;

  Future<Result<void>> call({
    required AuthUser client,
    required Merchant merchant,
  }) async {
    if (client.id.isEmpty) {
      return const Left<AppFailure, void>(
        UnexpectedFailure(message: 'Utilisateur non connecté'),
      );
    }
    if (!isBlePassageAllowedForMerchant(merchant)) {
      final live = merchantLiveLoyaltyProgram(merchant);
      if (!merchant.loyaltyEnabled || !live.programEnabled) {
        return Left<AppFailure, void>(MerchantLoyaltyInactiveFailure());
      }
      return const Left<AppFailure, void>(
        BlePassageSessionFailure(
          'Ce commerce valide les passages manuellement depuis la vitrine. '
          'Utilisez « Demander un passage » sur sa fiche.',
        ),
      );
    }

    final config = merchantLiveLoyaltyProgram(merchant);

    final followCheck = await _ensureFollow.call(
      clientUid: client.id,
      merchant: merchant,
    );
    final followBlocked = followCheck.fold((f) => f, (_) => null);
    if (followBlocked != null) {
      return Left<AppFailure, void>(followBlocked);
    }

    final displayName = client.displayName?.trim().isNotEmpty == true
        ? client.displayName!.trim()
        : (client.email?.split('@').first.trim() ?? 'Client');
    final merchantName = merchant.displayName?.trim().isNotEmpty == true
        ? merchant.displayName!.trim()
        : merchant.name;

    return _validationRepo.createBleSession(
      merchantId: merchant.id,
      clientUid: client.id,
      clientDisplayName: displayName,
      clientPhotoUrl: client.photoUrl,
      programSnapshot: config,
      merchantDisplayName: merchantName,
    );
  }
}
