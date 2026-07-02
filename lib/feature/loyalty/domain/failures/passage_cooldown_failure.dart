import '../../../../core/domain/core/failure.dart';

/// Last validated passage at this merchant is more recent than the
/// 1-hour cooldown window. The message is the canonical user-visible
/// French copy — sheets, snackbars and analytics keys all consume it.
///
/// The cooldown is enforced both client-side ([FirestoreClientLoyaltyRepository])
/// and server-side ([firestore.rules]) — see `kPassageCooldown`. Catching
/// this typed failure is preferred over substring matching the message,
/// which is still supported for legacy paths.
final class PassageCooldownFailure extends AppFailure {
  const PassageCooldownFailure({
    String message =
        'Votre passage vient d’être enregistré. Patientez 1 heure avant un nouveau passage chez ce commerçant.',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);
}
