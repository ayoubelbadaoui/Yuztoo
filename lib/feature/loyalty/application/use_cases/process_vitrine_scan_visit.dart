import '../../../auth/core/domain/entities/auth_user.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../domain/entities/client_merchant_loyalty_progress.dart';
import '../../domain/failures/passage_cooldown_failure.dart';
import '../../domain/loyalty_passage_program_policy.dart';
import '../analytics/nfc_analytics.dart';
import 'record_client_visit_passage.dart';
import 'request_active_validation.dart';

/// Outcome of a vitrine scan (NFC tag tap, in-app NFC read, QR scan,
/// universal-link arrival). Sealed so callers can `switch` on it
/// exhaustively and so adding a branch later forces a UI update.
sealed class ScanVisitResult {
  const ScanVisitResult();
}

/// Client is not signed in. Storefront is shown without modal.
final class ScanVisitGuest extends ScanVisitResult {
  const ScanVisitGuest();
}

/// The follow list is still loading. The caller should wait and re-invoke
/// once `isFollowListReady` flips to true — branching on `isFollowing`
/// before the data is in is what produced the legacy "scanned and forgot
/// I follow this shop" bug.
final class ScanVisitFollowListNotReady extends ScanVisitResult {
  const ScanVisitFollowListNotReady();
}

/// Client is signed in but does not follow this merchant. Per MVP the
/// storefront opens with no forced modal; the caller may decide to show
/// a non-blocking welcome / follow sheet on top.
final class ScanVisitNotFollowing extends ScanVisitResult {
  const ScanVisitNotFollowing();
}

/// Loyalty programme is OFF for this merchant — only the storefront is
/// shown. The scan still counts as discovery; no passage is recorded.
final class ScanVisitLoyaltyInactive extends ScanVisitResult {
  const ScanVisitLoyaltyInactive();
}

/// Automatic mode succeeded: the visit was written silently. UI must
/// invalidate `clientLoyaltyProgressForMerchantProvider` and play the
/// celebration overlay.
final class ScanVisitVisitRecorded extends ScanVisitResult {
  const ScanVisitVisitRecorded(this.progress);

  final ClientMerchantLoyaltyProgress progress;
}

/// Manual mode: an `active_validations` session was created. The
/// merchant queue listener will pop the per-program form. The client
/// listens on its own session doc to render the live "validation en
/// cours" banner.
final class ScanVisitAwaitingMerchant extends ScanVisitResult {
  const ScanVisitAwaitingMerchant();
}

/// Last passage at this merchant is still inside the 1-hour cooldown.
/// The message is the canonical French copy from
/// [PassageCooldownFailure] — surface it as an info snackbar (not red).
final class ScanVisitCooldownBlocked extends ScanVisitResult {
  const ScanVisitCooldownBlocked(this.userMessage);

  final String userMessage;
}

/// Generic failure with a French user-visible message. Routed to the
/// regular error snackbar.
final class ScanVisitError extends ScanVisitResult {
  const ScanVisitError(this.userMessage);

  final String userMessage;
}

/// Application-layer orchestration for a vitrine scan.
///
/// Replaces the inline branching that used to live in
/// `_handleVitrineScanArrival` (store_profile_screen.part.dart) and the
/// duplicate path in the in-app QR scanner. Centralising the rules here
/// is what lets every entry point — NFC tag tap, deep link, in-app QR,
/// in-app NFC, debug simulate — behave identically.
///
/// Inputs:
/// - [client]: the authenticated user, or `null` for a guest scan.
/// - [merchant]: the resolved storefront. Loyalty mode is read from the
///   live merchant doc via the existing policy helpers.
/// - [isFollowing]: whether the client follows this merchant. Caller is
///   responsible for resolving this from the follow-list provider.
/// - [isFollowListReady]: gate that prevents the use case from acting on
///   stale data. While `false`, the caller should wait — typically the
///   `_handleVitrineScanArrival` post-frame retry pattern.
///
/// The use case never throws; every error path returns a
/// [ScanVisitResult] subtype with French-localised copy.
class ProcessVitrineScanVisit {
  const ProcessVitrineScanVisit({
    required RecordClientVisitPassage recordVisit,
    required RequestActiveValidation requestValidation,
    NfcAnalytics analytics = const NfcAnalytics(),
  })  : _recordVisit = recordVisit,
        _requestValidation = requestValidation,
        _analytics = analytics;

  final RecordClientVisitPassage _recordVisit;
  final RequestActiveValidation _requestValidation;
  final NfcAnalytics _analytics;

  Future<ScanVisitResult> call({
    required AuthUser? client,
    required Merchant merchant,
    required bool isFollowing,
    required bool isFollowListReady,
  }) async {
    final clientUid = client?.id ?? '';
    _analytics.logEvent(
      NfcAnalyticsEvent.scanArrival,
      parameters: <String, Object?>{
        'merchant_id': merchant.id,
        'authed': clientUid.isNotEmpty,
        'is_following': isFollowing,
        'follow_list_ready': isFollowListReady,
      },
    );

    final ScanVisitResult result = await _resolve(
      client: client,
      clientUid: clientUid,
      merchant: merchant,
      isFollowing: isFollowing,
      isFollowListReady: isFollowListReady,
    );

    _analytics.logEvent(
      _eventForResult(result),
      parameters: <String, Object?>{'merchant_id': merchant.id},
    );
    return result;
  }

  Future<ScanVisitResult> _resolve({
    required AuthUser? client,
    required String clientUid,
    required Merchant merchant,
    required bool isFollowing,
    required bool isFollowListReady,
  }) async {
    if (client == null || clientUid.isEmpty) {
      return const ScanVisitGuest();
    }
    if (!isFollowListReady) {
      return const ScanVisitFollowListNotReady();
    }
    if (!isFollowing) {
      return const ScanVisitNotFollowing();
    }
    if (!isMerchantLoyaltyPassageActive(merchant)) {
      return const ScanVisitLoyaltyInactive();
    }

    if (isVitrinePassageRequestAllowedForMerchant(merchant)) {
      final outcome = await _requestValidation(
        client: client,
        merchant: merchant,
      );
      return outcome.fold(
        (failure) => ScanVisitError(failure.message),
        (_) => const ScanVisitAwaitingMerchant(),
      );
    }

    if (isAutomaticPassageAllowedForMerchant(merchant)) {
      final outcome = await _recordVisit(
        clientUid: clientUid,
        merchant: merchant,
      );
      return outcome.fold(
        (failure) {
          if (failure is PassageCooldownFailure) {
            return ScanVisitCooldownBlocked(failure.message);
          }
          return ScanVisitError(failure.message);
        },
        ScanVisitVisitRecorded.new,
      );
    }

    return const ScanVisitLoyaltyInactive();
  }

  static String _eventForResult(ScanVisitResult result) {
    return switch (result) {
      ScanVisitGuest() => NfcAnalyticsEvent.scanResultGuest,
      ScanVisitFollowListNotReady() => NfcAnalyticsEvent.scanResultGuest,
      ScanVisitNotFollowing() => NfcAnalyticsEvent.scanResultNotFollowing,
      ScanVisitLoyaltyInactive() =>
        NfcAnalyticsEvent.scanResultLoyaltyInactive,
      ScanVisitVisitRecorded() => NfcAnalyticsEvent.scanResultVisitRecorded,
      ScanVisitAwaitingMerchant() =>
        NfcAnalyticsEvent.scanResultAwaitingMerchant,
      ScanVisitCooldownBlocked() =>
        NfcAnalyticsEvent.scanResultCooldownBlocked,
      ScanVisitError() => NfcAnalyticsEvent.scanResultError,
    };
  }
}
