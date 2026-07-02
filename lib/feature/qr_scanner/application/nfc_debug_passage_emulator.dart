import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/domain/entities/auth_user.dart';
import '../../loyalty/application/client_loyalty_providers.dart';
import '../../loyalty/application/use_cases/process_vitrine_scan_visit.dart';
import '../../loyalty/domain/loyalty_passage_program_policy.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../../store_profile/application/nfc_debug_providers.dart';
import '../../store_profile/application/providers.dart'
    as store_profile_providers;

/// One checklist row for the NFC passage debug tab.
class NfcDebugPassageCheck {
  const NfcDebugPassageCheck({
    required this.label,
    required this.ok,
    this.detail,
  });

  final String label;
  final bool ok;
  final String? detail;
}

/// Outcome of preflight before emulating « tap NFC → passage Firestore ».
class NfcDebugPassagePreflight {
  const NfcDebugPassagePreflight({
    required this.checks,
    required this.canEmulatePassage,
    required this.expectedOutcome,
  });

  final List<NfcDebugPassageCheck> checks;
  final bool canEmulatePassage;
  final String expectedOutcome;
}

/// Runs the real [ProcessVitrineScanVisit] path after a simulated NFC tap
/// (vitrine navigation + scan intent). No forced UI overrides.
abstract final class NfcDebugPassageEmulator {
  static Future<NfcDebugPassagePreflight> preflight(
    WidgetRef ref,
    String merchantId,
  ) async {
    final id = merchantId.trim();
    final checks = <NfcDebugPassageCheck>[];

    final auth = ref.read(authStateProvider);
    AuthUser? client;
    if (auth is Authenticated) {
      client = auth.user;
      checks.add(const NfcDebugPassageCheck(
        label: 'Connecté en tant que client',
        ok: true,
      ));
    } else {
      checks.add(const NfcDebugPassageCheck(
        label: 'Connecté en tant que client',
        ok: false,
        detail: 'Connectez-vous avec un compte client.',
      ));
    }

    if (id.isEmpty) {
      checks.add(const NfcDebugPassageCheck(
        label: 'ID commerce renseigné',
        ok: false,
        detail: 'Choisissez un commerce dans le champ ci-dessus.',
      ));
      return NfcDebugPassagePreflight(
        checks: checks,
        canEmulatePassage: false,
        expectedOutcome: '—',
      );
    }

    checks.add(const NfcDebugPassageCheck(
      label: 'ID commerce renseigné',
      ok: true,
    ));

    final merchantResult =
        await ref.read(merchantRepositoryProvider).getMerchantById(id);
    Merchant? merchant;
    merchantResult.fold(
      (_) => checks.add(const NfcDebugPassageCheck(
        label: 'Commerce trouvé dans Firestore',
        ok: false,
        detail: 'Vérifiez l’ID ou votre connexion.',
      )),
      (m) {
        if (m == null) {
          checks.add(NfcDebugPassageCheck(
            label: 'Commerce trouvé dans Firestore',
            ok: false,
            detail: 'Aucun document merchants/$id.',
          ));
        } else {
          merchant = m;
          checks.add(NfcDebugPassageCheck(
            label: 'Commerce trouvé dans Firestore',
            ok: true,
            detail: m.displayName?.isNotEmpty == true
                ? m.displayName
                : m.name,
          ));
        }
      },
    );

    final m = merchant;
    if (m == null) {
      return NfcDebugPassagePreflight(
        checks: checks,
        canEmulatePassage: false,
        expectedOutcome: '—',
      );
    }

    final followAsync =
        ref.read(store_profile_providers.followedMerchantIdsForCurrentUserProvider);
    final followReady = !followAsync.isLoading;
    final following =
        followReady && (followAsync.valueOrNull?.contains(id) ?? false);

    checks.add(NfcDebugPassageCheck(
      label: 'Liste « boutiques suivies » prête',
      ok: followReady,
      detail: followReady ? null : 'Attendez le chargement du carnet.',
    ));

    if (client != null) {
      checks.add(NfcDebugPassageCheck(
        label: 'Vous suivez ce commerce',
        ok: following,
        detail: following
            ? null
            : 'Suivez la boutique avant d’enregistrer un passage.',
      ));
    }

    final loyaltyActive = isMerchantLoyaltyPassageActive(m);
    checks.add(NfcDebugPassageCheck(
      label: 'Programme fidélité actif',
      ok: loyaltyActive,
      detail: loyaltyActive
          ? null
          : 'Activez la fidélité côté commerçant.',
    ));

    String expectedOutcome;
    if (isAutomaticPassageAllowedForMerchant(m)) {
      expectedOutcome =
          'Passage enregistré dans Firestore (mode auto) + overlay célébration.';
      checks.add(const NfcDebugPassageCheck(
        label: 'Mode passage : automatique (NFC/QR)',
        ok: true,
      ));
    } else if (isVitrinePassageRequestAllowedForMerchant(m)) {
      expectedOutcome =
          'Session active_validations créée — le commerçant valide dans sa file.';
      checks.add(const NfcDebugPassageCheck(
        label: 'Mode passage : validation commerçant (manuel)',
        ok: true,
      ));
    } else if (loyaltyActive) {
      expectedOutcome = 'Fidélité active mais mode passage non reconnu.';
      checks.add(const NfcDebugPassageCheck(
        label: 'Mode passage compatible NFC',
        ok: false,
        detail: 'Réglez le mode dans E-Fidélité (auto ou manuel vitrine).',
      ));
    } else {
      expectedOutcome = 'Vitrine seule — pas de passage.';
    }

    final canEmulate = client != null &&
        followReady &&
        following &&
        loyaltyActive &&
        (isAutomaticPassageAllowedForMerchant(m) ||
            isVitrinePassageRequestAllowedForMerchant(m));

    return NfcDebugPassagePreflight(
      checks: checks,
      canEmulatePassage: canEmulate,
      expectedOutcome: expectedOutcome,
    );
  }

  /// Clears any forced funnel override, sets scan intent via navigation
  /// callback, and lets [ProcessVitrineScanVisit] run on the storefront.
  static void emulateNfcTapNavigateToRealPassage({
    required WidgetRef ref,
    required String merchantId,
    required void Function(String merchantId) onNavigateToVitrine,
  }) {
    ref.read(nfcDebugForcedScanVisitResultProvider.notifier).state = null;
    onNavigateToVitrine(merchantId.trim());
  }

  /// Runs [ProcessVitrineScanVisit] immediately (without navigation) for QA
  /// feedback in the debug sheet. Returns the same result the storefront
  /// would apply after a real NFC tap.
  static Future<ScanVisitResult> runRealPassageInProcess({
    required WidgetRef ref,
    required String merchantId,
  }) async {
    final id = merchantId.trim();
    final auth = ref.read(authStateProvider);
    final client = auth is Authenticated ? auth.user : null;

    final merchantResult =
        await ref.read(merchantRepositoryProvider).getMerchantById(id);
    final merchant = merchantResult.fold<Merchant?>(
      (_) => null,
      (m) => m,
    );
    if (merchant == null) {
      return const ScanVisitError('Commerce introuvable.');
    }

    final followAsync =
        ref.read(store_profile_providers.followedMerchantIdsForCurrentUserProvider);
    final isFollowing = followAsync.valueOrNull?.contains(id) ?? false;
    final followReady = !followAsync.isLoading;

    return ref.read(processVitrineScanVisitProvider)(
      client: client,
      merchant: merchant,
      isFollowing: isFollowing,
      isFollowListReady: followReady,
    );
  }

  static String resultSummary(ScanVisitResult result) {
    return switch (result) {
      ScanVisitGuest() =>
        'Invité — pas de passage (sheet connexion sur la vitrine).',
      ScanVisitFollowListNotReady() =>
        'Liste des suivis en cours de chargement — réessayez.',
      ScanVisitNotFollowing() =>
        'Non-suiveur — pas de passage (sheet « Suivre » sur la vitrine).',
      ScanVisitLoyaltyInactive() =>
        'Fidélité inactive — vitrine sans passage.',
      ScanVisitVisitRecorded(:final progress) =>
        'Passage enregistré — ${progress.validatedPassages} passage(s) validé(s).',
      ScanVisitAwaitingMerchant() =>
        'Session créée — en attente de validation commerçant.',
      ScanVisitCooldownBlocked(:final userMessage) => userMessage,
      ScanVisitError(:final userMessage) => userMessage,
    };
  }
}
