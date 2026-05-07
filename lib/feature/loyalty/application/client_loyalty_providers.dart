import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../../client_home/application/providers.dart'
    show followedMerchantIdsForCurrentUserProvider;
import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../domain/entities/client_merchant_loyalty_progress.dart';
import '../domain/entities/client_reward_item.dart';
import '../infrastructure/client_loyalty_repository_provider.dart';
import 'use_cases/claim_welcome_bon.dart';
import 'use_cases/record_loyalty_passage.dart';
import 'use_cases/redeem_loyalty_reward.dart';
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

final redeemLoyaltyRewardProvider = Provider<RedeemLoyaltyReward>((ref) {
  return RedeemLoyaltyReward(ref.watch(clientLoyaltyRepositoryProvider));
});

final claimWelcomeBonProvider = Provider<ClaimWelcomeBon>((ref) {
  return ClaimWelcomeBon(ref.watch(clientLoyaltyRepositoryProvider));
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

/// Clients who have earned a reward (passed the threshold) — merchant can
/// mark their reward as used to reset the cycle.
///
/// Parameterised by the merchant entity so both trigger types are handled.
final clientsWithRewardAvailableProvider = StreamProvider.autoDispose
    .family<List<LoyaltyPendingClientRow>, ({String merchantId, int visitsRequired, double spendRequired, bool isSpendBased})>(
  (ref, params) {
    if (params.merchantId.isEmpty) {
      return Stream<List<LoyaltyPendingClientRow>>.value(
        <LoyaltyPendingClientRow>[],
      );
    }
    final repo = ref.watch(clientLoyaltyRepositoryProvider);
    return repo.watchClientsWithRewardAvailable(
      merchantId: params.merchantId,
      visitsRequired: params.visitsRequired,
      spendRequiredEuros: params.spendRequired,
      iSpendBased: params.isSpendBased,
    );
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
    this.isOwnMerchant = false,
  });

  final Merchant merchant;
  final LoyaltyProgramConfig config;

  /// True when this entry is the user's own merchant (prepended for dual-profile
  /// testing). It is NOT a "followed" merchant — the count shown to the user
  /// should exclude it from the "X suivis" subtitle.
  final bool isOwnMerchant;

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
    final cfg = ownMerchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(
            loyaltyEnabled: ownMerchant.loyaltyEnabled);
    if (ownMerchant.loyaltyEnabled && cfg.programEnabled) {
      entries.add(ClientLoyaltyEntry(
        merchant: ownMerchant,
        config: cfg,
        isOwnMerchant: true,
      ));
    }
  }

  for (final m in followedMerchants) {
    final e = toEntry(m);
    if (e != null) entries.add(e);
  }

  return entries;
});

// ─── "Mes avantages" — aggregated rewards across followed merchants ───────────

/// All redeemable bons currently visible to the connected client, ordered by
/// kind (welcome first, then milestone) and then by merchant name.
///
/// Resolution per loyalty entry:
///   - Welcome bon: loyalty doc has `first_visit_at`, the merchant has a
///     non-empty welcome gift, AND `welcome_bon_claimed_at` is null.
///   - Milestone bon: progress meets/exceeds the configured threshold (one
///     bon shown even if the client is multiple cycles ahead — the merchant's
///     "Donner le bon" flow decrements per claim, and the next cycle's bon
///     reappears once the deduction lands).
///
/// Implemented as a `FutureProvider` rather than a stream because the loyalty
/// feed itself is a Future. Per-merchant progress is fetched once via
/// `repo.watchProgress(...).first` so the aggregate has a single emission;
/// the underlying card view continues to subscribe to the live stream and
/// will refresh independently when a passage lands.
final availableClientRewardsProvider =
    FutureProvider.autoDispose<List<ClientRewardItem>>((ref) async {
  final entries = await ref.watch(clientLoyaltyFeedProvider.future);
  if (entries.isEmpty) return <ClientRewardItem>[];

  final repo = ref.watch(clientLoyaltyRepositoryProvider);
  final auth = ref.watch(auth_providers.authStateProvider);
  if (auth is! Authenticated) return <ClientRewardItem>[];
  final clientUid = auth.user.id;

  // Fetch each merchant's current progress in parallel.
  final progresses = await Future.wait(
    entries.map(
      (e) =>
          repo.watchProgress(e.merchantId, clientUid).first.catchError(
                (_) => const ClientMerchantLoyaltyProgress.empty(),
              ),
    ),
  );

  final rewards = <ClientRewardItem>[];

  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final progress = progresses[i];
    final welcomeGift = entry.merchant.welcomeGiftDescription?.trim() ?? '';

    // Welcome bon: one-shot, claimable.
    if (progress.hasFirstVisit &&
        !progress.welcomeBonClaimed &&
        welcomeGift.isNotEmpty) {
      rewards.add(ClientRewardItem(
        merchant: entry.merchant,
        kind: ClientRewardKind.welcome,
        title: 'Bon de bienvenue',
        description: welcomeGift,
        actionable: true,
      ));
    }

    // Milestone bon: shown when threshold reached. NOT actionable from
    // client side in v1 — the existing merchant flow validates and
    // decrements.
    if (entry.isRewardAvailable(progress)) {
      rewards.add(ClientRewardItem(
        merchant: entry.merchant,
        kind: ClientRewardKind.milestone,
        title: 'Bon fidélité disponible',
        description: entry.rewardLabel(),
        actionable: false,
      ));
    }
  }

  // Welcome bons first (the most "delightful" reveal), then milestones.
  // Stable secondary sort by merchant display name for deterministic UI.
  rewards.sort((a, b) {
    if (a.kind != b.kind) {
      return a.kind == ClientRewardKind.welcome ? -1 : 1;
    }
    final an = a.merchant.displayName ?? a.merchant.name;
    final bn = b.merchant.displayName ?? b.merchant.name;
    return an.toLowerCase().compareTo(bn.toLowerCase());
  });

  return rewards;
});
