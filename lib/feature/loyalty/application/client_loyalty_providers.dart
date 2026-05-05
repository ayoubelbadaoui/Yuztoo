import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../../client_home/application/providers.dart'
    show followedMerchantIdsForCurrentUserProvider;
import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../domain/entities/client_merchant_loyalty_progress.dart';
import '../infrastructure/client_loyalty_repository_provider.dart';
import 'use_cases/record_loyalty_passage.dart';
import 'use_cases/validate_pending_loyalty_passage.dart';
import '../domain/entities/loyalty_pending_client_row.dart';

export '../../auth/core/application/providers.dart'
    show authStateProvider, userProfileBasicsProvider;
export '../../auth/core/application/state/auth_state.dart'
    show AuthState, Authenticated;

// ─── Use-case providers ────────────────────────────────────────────────────────

final recordLoyaltyPassageProvider = Provider<RecordLoyaltyPassage>((ref) {
  return RecordLoyaltyPassage(ref.watch(clientLoyaltyRepositoryProvider));
});

final validatePendingLoyaltyPassageProvider =
    Provider<ValidatePendingLoyaltyPassage>((ref) {
  return ValidatePendingLoyaltyPassage(
      ref.watch(clientLoyaltyRepositoryProvider));
});

// ─── Per-merchant progress stream ─────────────────────────────────────────────

/// Progression fidélité du client connecté pour un commerce.
final clientLoyaltyProgressForMerchantProvider =
    StreamProvider.autoDispose.family<ClientMerchantLoyaltyProgress, String>(
  (ref, merchantId) {
    final auth = ref.watch(auth_providers.authStateProvider);
    if (auth is! Authenticated) {
      return Stream<ClientMerchantLoyaltyProgress>.value(
        const ClientMerchantLoyaltyProgress.empty(),
      );
    }
    final repo = ref.watch(clientLoyaltyRepositoryProvider);
    return repo.watchProgress(merchantId, auth.user.id);
  },
);

/// Loyalty progress for a specific client at a specific merchant (merchant CRM).
/// Used by the merchant to see a client's passage count in the detail sheet.
final merchantClientLoyaltyProgressProvider = StreamProvider.autoDispose.family<
    ClientMerchantLoyaltyProgress,
    ({String merchantId, String clientUid})>(
  (ref, params) {
    if (params.merchantId.isEmpty || params.clientUid.isEmpty) {
      return Stream<ClientMerchantLoyaltyProgress>.value(
        const ClientMerchantLoyaltyProgress.empty(),
      );
    }
    return ref
        .watch(clientLoyaltyRepositoryProvider)
        .watchProgress(params.merchantId, params.clientUid);
  },
);

/// Passages en attente (validation manuelle) pour un commerce.
final pendingLoyaltyClientsForMerchantProvider = StreamProvider.autoDispose
    .family<List<LoyaltyPendingClientRow>, String>(
  (ref, merchantId) {
    if (merchantId.isEmpty) {
      return Stream<List<LoyaltyPendingClientRow>>.value(
        <LoyaltyPendingClientRow>[],
      );
    }
    final repo = ref.watch(clientLoyaltyRepositoryProvider);
    return repo.watchPendingLoyaltyClients(merchantId);
  },
);

// ─── Loyalty feed for client tab ───────────────────────────────────────────────

/// A merchant the client follows that has an active loyalty program.
class ClientLoyaltyEntry {
  const ClientLoyaltyEntry({
    required this.merchant,
    required this.config,
  });

  final Merchant merchant;
  final LoyaltyProgramConfig config;

  String get merchantId => merchant.id;
  String get merchantName =>
      merchant.displayName?.isNotEmpty == true ? merchant.displayName! : merchant.name;
  String? get logoUrl => merchant.logoUrl;

  /// Progress fraction for [visitCount] programs (clamped 0–1).
  double progressFraction(ClientMerchantLoyaltyProgress p) {
    if (config.triggerType == LoyaltyTriggerType.visitCount &&
        config.visitsRequired > 0) {
      return (p.validatedPassages / config.visitsRequired).clamp(0.0, 1.0);
    }
    if (config.triggerType == LoyaltyTriggerType.purchaseTotal &&
        config.cumulativeSpendRequiredEuros > 0) {
      return (p.cumulativeSpendEuros / config.cumulativeSpendRequiredEuros)
          .clamp(0.0, 1.0);
    }
    return 0.0;
  }

  bool isRewardAvailable(ClientMerchantLoyaltyProgress p) {
    if (config.triggerType == LoyaltyTriggerType.visitCount) {
      return p.validatedPassages >= config.visitsRequired;
    }
    return p.cumulativeSpendEuros >= config.cumulativeSpendRequiredEuros;
  }

  String progressLabel(ClientMerchantLoyaltyProgress p) {
    if (config.triggerType == LoyaltyTriggerType.visitCount) {
      return '${p.validatedPassages} / ${config.visitsRequired} passages';
    }
    final spent = p.cumulativeSpendEuros.toStringAsFixed(0);
    final needed = config.cumulativeSpendRequiredEuros.toStringAsFixed(0);
    return '$spent € / $needed €';
  }

  String rewardLabel() {
    switch (config.rewardKind) {
      case LoyaltyRewardKind.purchaseVoucher:
        if (config.purchaseVoucherUsesPercent) {
          return 'Bon d\'achat ${config.purchaseVoucherValue.toStringAsFixed(0)} %';
        }
        return 'Bon d\'achat ${config.purchaseVoucherValue.toStringAsFixed(0)} €';
      case LoyaltyRewardKind.discountPercent:
        return 'Remise ${config.discountNextPurchasePercent.toStringAsFixed(0)} %';
      case LoyaltyRewardKind.freeProduct:
        return config.freeProductSummaryLabel?.isNotEmpty == true
            ? 'Offert : ${config.freeProductSummaryLabel}'
            : 'Produit offert';
      case LoyaltyRewardKind.loyaltyPoints:
        return 'Points fidélité';
    }
  }
}

/// Followed merchants that have an active loyalty program.
/// Used by the client Fidélité tab.
/// When the authenticated user also owns a merchant profile (dual-role),
/// that merchant is prepended so they can view/test their own carnet.
final clientLoyaltyFeedProvider =
    FutureProvider.autoDispose<List<ClientLoyaltyEntry>>((ref) async {
  final auth = ref.watch(auth_providers.authStateProvider);
  if (auth is! Authenticated) return <ClientLoyaltyEntry>[];

  final userId = auth.user.id;
  final repo = ref.watch(merchantRepositoryProvider);

  // Run own-merchant lookup and followed-ids lookup in parallel.
  final ownMerchantFuture = repo.getMerchantById(userId);
  final idsFuture = ref.watch(followedMerchantIdsForCurrentUserProvider.future);

  final ownMerchantResult = await ownMerchantFuture;
  final ids = await idsFuture;

  final Merchant? ownMerchant = ownMerchantResult.fold((_) => null, (m) => m);

  // Followed merchants (exclude own store to avoid duplicate).
  final filteredIds = ids.where((id) => id != userId).toList();
  final followedMerchants = filteredIds.isEmpty
      ? <Merchant>[]
      : (await repo.getMerchantsByIds(filteredIds))
          .fold((_) => <Merchant>[], (list) => list);

  ClientLoyaltyEntry? toEntry(Merchant m) {
    final cfg = m.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: m.loyaltyEnabled);
    if (!m.loyaltyEnabled || !cfg.programEnabled) return null;
    return ClientLoyaltyEntry(merchant: m, config: cfg);
  }

  final entries = <ClientLoyaltyEntry>[];

  // Prepend own merchant (if they have loyalty enabled) so a merchant-as-client
  // can always see their own carnet — even without following themselves.
  if (ownMerchant != null) {
    final e = toEntry(ownMerchant);
    if (e != null) entries.add(e);
  }

  for (final m in followedMerchants) {
    final e = toEntry(m);
    if (e != null) entries.add(e);
  }

  return entries;
});
