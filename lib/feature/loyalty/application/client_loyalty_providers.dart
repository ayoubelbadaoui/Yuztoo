import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../../followed_merchants/infrastructure/followed_merchants_repository_provider.dart';
import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../domain/entities/client_bon.dart';
import '../domain/entities/client_merchant_loyalty_progress.dart';
import '../domain/entities/client_reward_item.dart';
import '../infrastructure/client_bon_repository_provider.dart';
import '../infrastructure/client_loyalty_repository_provider.dart';
import 'active_validation_providers.dart';
import 'use_cases/claim_welcome_bon.dart';
import 'use_cases/process_vitrine_scan_visit.dart';
import 'use_cases/record_client_visit_passage.dart';
import 'use_cases/redeem_loyalty_reward.dart';
import '../domain/entities/loyalty_pending_client_row.dart';

export '../../auth/core/application/providers.dart'
    show authStateProvider, userProfileBasicsProvider;
export '../../auth/core/application/state/auth_state.dart'
    show AuthState, Authenticated;

// ─── Use-case providers ────────────────────────────────────────────────────────

final recordClientVisitPassageProvider = Provider<RecordClientVisitPassage>((ref) {
  return RecordClientVisitPassage(ref.watch(clientLoyaltyRepositoryProvider));
});

final redeemLoyaltyRewardProvider = Provider<RedeemLoyaltyReward>((ref) {
  return RedeemLoyaltyReward(ref.watch(clientLoyaltyRepositoryProvider));
});

final claimWelcomeBonProvider = Provider<ClaimWelcomeBon>((ref) {
  return ClaimWelcomeBon(ref.watch(clientLoyaltyRepositoryProvider));
});

/// Application use case that orchestrates a vitrine scan (NFC, QR,
/// universal link) and returns a [ScanVisitResult] the UI consumes
/// uniformly. See [ProcessVitrineScanVisit] for the branching rules.
final processVitrineScanVisitProvider =
    Provider<ProcessVitrineScanVisit>((ref) {
  return ProcessVitrineScanVisit(
    recordVisit: ref.watch(recordClientVisitPassageProvider),
    requestValidation: ref.watch(requestActiveValidationProvider),
  );
});

/// One-shot signal: a passage was just recorded directly via scan
/// (NFC tag, QR, deep link), without going through `active_validations`.
///
/// The [LoyaltyCelebrationOverlay] watches this provider so it can fire
/// the gold celebration immediately, instead of waiting for an
/// active_validations doc that the automatic flow never creates.
///
/// Set the value to the merchantId on a successful direct visit. The
/// overlay clears the state to null after celebrating, so the same
/// merchant scan can re-trigger on the next cycle.
final pendingDirectVisitCelebrationProvider =
    StateProvider<String?>((ref) => null);

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

// ─── Loyalty feed for client tab ───────────────────────────────────────────────

/// A merchant the client follows that has an active loyalty program.
/// Whether two program configs differ on reward/threshold axes (grandfathering).
bool loyaltyProgramsDiffer(
  LoyaltyProgramConfig a,
  LoyaltyProgramConfig b,
) {
  return a.programEnabled != b.programEnabled ||
      a.rewardKind != b.rewardKind ||
      a.triggerType != b.triggerType ||
      a.visitsRequired != b.visitsRequired ||
      (a.cumulativeSpendRequiredEuros - b.cumulativeSpendRequiredEuros).abs() >
          0.01 ||
      a.minimumPerVisitEnabled != b.minimumPerVisitEnabled ||
      ((a.minimumPerVisitEuros ?? 0) - (b.minimumPerVisitEuros ?? 0)).abs() >
          0.01 ||
      a.rewardValidityEnabled != b.rewardValidityEnabled ||
      (a.rewardValidityDays ?? 0) != (b.rewardValidityDays ?? 0) ||
      a.optionalAskClientPurchaseAmount != b.optionalAskClientPurchaseAmount;
}

class ClientLoyaltyEntry {
  const ClientLoyaltyEntry({
    required this.merchant,
    required this.config,
    this.isOwnMerchant = false,
    this.programEnded = false,
  });

  final Merchant merchant;
  final LoyaltyProgramConfig config;

  /// Merchant disabled loyalty; client keeps enrolled progress/rewards.
  final bool programEnded;

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

List<ClientLoyaltyEntry> _loyaltyEntriesFromCandidates({
  required List<Merchant> candidates,
  required Merchant? ownMerchant,
  required List<Merchant> followedMerchants,
  required Map<String, ClientMerchantLoyaltyProgress> progressByMerchant,
}) {
  ClientLoyaltyEntry? toEntry(Merchant m, {required bool isOwn}) {
    final liveCfg = m.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: m.loyaltyEnabled);
    final progress = progressByMerchant[m.id] ??
        const ClientMerchantLoyaltyProgress.empty();
    final enrolled = progress.enrolledProgram;

    if (m.loyaltyEnabled && liveCfg.programEnabled) {
      final cfg = enrolled ?? liveCfg;
      return ClientLoyaltyEntry(merchant: m, config: cfg, isOwnMerchant: isOwn);
    }

    if (enrolled != null) {
      return ClientLoyaltyEntry(
        merchant: m,
        config: enrolled,
        isOwnMerchant: isOwn,
        programEnded: !m.loyaltyEnabled || !liveCfg.programEnabled,
      );
    }
    return null;
  }

  final entries = <ClientLoyaltyEntry>[];
  final seen = <String>{};

  if (ownMerchant != null) {
    final e = toEntry(ownMerchant, isOwn: true);
    if (e != null) {
      entries.add(e);
      seen.add(ownMerchant.id);
    }
  }

  for (final m in followedMerchants) {
    if (seen.contains(m.id)) continue;
    final e = toEntry(m, isOwn: false);
    if (e != null) entries.add(e);
  }

  return entries;
}

/// Live loyalty carnet: followed ids + per-merchant progress streams.
final clientLoyaltyFeedProvider =
    StreamProvider.autoDispose<List<ClientLoyaltyEntry>>((ref) {
  final auth = ref.watch(auth_providers.authStateProvider);
  if (auth is! Authenticated) {
    return Stream<List<ClientLoyaltyEntry>>.value(const <ClientLoyaltyEntry>[]);
  }

  final userId = auth.user.id;
  final merchantRepo = ref.read(merchantRepositoryProvider);
  final loyaltyRepo = ref.read(clientLoyaltyRepositoryProvider);
  final followedRepo = ref.read(followedMerchantsRepositoryProvider);

  final controller = StreamController<List<ClientLoyaltyEntry>>.broadcast();
  final progressSubs = <StreamSubscription<ClientMerchantLoyaltyProgress>>[];
  StreamSubscription<List<String>>? followedSub;

  void emitEntries({
    required Merchant? ownMerchant,
    required List<Merchant> followedMerchants,
    required Map<String, ClientMerchantLoyaltyProgress> progressByMerchant,
  }) {
    if (controller.isClosed) return;
    controller.add(
      _loyaltyEntriesFromCandidates(
        candidates: [
          if (ownMerchant != null) ownMerchant,
          ...followedMerchants,
        ],
        ownMerchant: ownMerchant,
        followedMerchants: followedMerchants,
        progressByMerchant: progressByMerchant,
      ),
    );
  }

  Future<void> bindProgressStreams({
    required Merchant? ownMerchant,
    required List<Merchant> followedMerchants,
  }) async {
    for (final s in progressSubs) {
      await s.cancel();
    }
    progressSubs.clear();

    final candidates = <Merchant>[
      if (ownMerchant != null) ownMerchant,
      ...followedMerchants,
    ];
    final progressByMerchant = <String, ClientMerchantLoyaltyProgress>{};
    await Future.wait(
      candidates.map((m) async {
        progressByMerchant[m.id] =
            await loyaltyRepo.readProgress(m.id, userId);
      }),
    );
    emitEntries(
      ownMerchant: ownMerchant,
      followedMerchants: followedMerchants,
      progressByMerchant: progressByMerchant,
    );

    for (final m in candidates) {
      progressSubs.add(
        loyaltyRepo.watchProgress(m.id, userId).listen((progress) {
          progressByMerchant[m.id] = progress;
          emitEntries(
            ownMerchant: ownMerchant,
            followedMerchants: followedMerchants,
            progressByMerchant: Map<String, ClientMerchantLoyaltyProgress>.from(
              progressByMerchant,
            ),
          );
        }),
      );
    }
  }

  followedSub = followedRepo.watchFollowedIds(userId).listen((ids) async {
    final ownMerchantResult = await merchantRepo.getMerchantById(userId);
    final ownMerchant = ownMerchantResult.fold((_) => null, (m) => m);
    final filteredIds = ids.where((id) => id != userId).toList();
    final followedMerchants = filteredIds.isEmpty
        ? <Merchant>[]
        : (await merchantRepo.getMerchantsByIds(filteredIds))
            .fold((_) => <Merchant>[], (list) => list);
    await bindProgressStreams(
      ownMerchant: ownMerchant,
      followedMerchants: followedMerchants,
    );
  });

  ref.onDispose(() async {
    await followedSub?.cancel();
    for (final s in progressSubs) {
      await s.cancel();
    }
    await controller.close();
  });

  return controller.stream;
});

// ─── "Mes avantages" — aggregated rewards across followed merchants ───────────

/// Live stream of all persisted bons for the connected client.
///
/// Wraps [ClientBonRepository.watchAll] as a `StreamProvider` so any consumer
/// that needs to react to issuance / redemption / expiry can either watch it
/// directly or, like [availableClientRewardsProvider] below, depend on it
/// via `.future` — Riverpod re-runs the dependent provider on every emission.
final _allClientBonsStreamProvider =
    StreamProvider.autoDispose<List<ClientBon>>((ref) {
  final auth = ref.watch(auth_providers.authStateProvider);
  if (auth is! Authenticated) {
    return Stream<List<ClientBon>>.value(const <ClientBon>[]);
  }
  return ref
      .watch(clientBonRepositoryProvider)
      .watchAll(auth.user.id);
});

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
/// Reactivity contract: this provider re-emits whenever any of its
/// dependencies changes — the loyalty feed, the per-merchant progress
/// stream, or the bons stream. Concretely that means a bon claimed on
/// another device, a merchant marking the welcome bon redeemed, or a
/// milestone crossing all flush through here without a manual invalidate.
/// (Previously this used `Stream.first` on the progress and bons streams,
/// capturing a one-shot snapshot that did not refresh — the user complaint
/// "le bon utilisé doit disparaitre" was caused by that.)
final availableClientRewardsProvider =
    FutureProvider.autoDispose<List<ClientRewardItem>>((ref) async {
  final entries = await ref.watch(clientLoyaltyFeedProvider.future);
  if (entries.isEmpty) return <ClientRewardItem>[];

  final auth = ref.watch(auth_providers.authStateProvider);
  if (auth is! Authenticated) return <ClientRewardItem>[];

  // Persisted bons are the source of truth: they carry valid_until_at
  // and survive merchant config changes. We still fall back to
  // on-the-fly computation for unmigrated merchants — anyone who
  // reached threshold or first-visit BEFORE the issuance CF was
  // deployed never got a bon doc, and we don't want their reward to
  // disappear silently.
  //
  // Hybrid resolution (per merchant):
  //   1. If a persisted bon exists for that (kind, merchantId), use it.
  //   2. Otherwise, fall back to the legacy on-the-fly inference.
  // This means a merchant with a persisted milestone bon will NEVER
  // also surface a fallback milestone bon for the same client even if
  // validated_passages also says "above threshold" — the persisted doc
  // wins on every read.
  //
  // The progress watches register synchronously (before any await), so
  // Riverpod sees the full dependency graph before the body suspends.
  final progressFutures = entries
      .map(
        (e) async {
          try {
            return await ref.watch(
              clientLoyaltyProgressForMerchantProvider(e.merchantId).future,
            );
          } catch (_) {
            return const ClientMerchantLoyaltyProgress.empty();
          }
        },
      )
      .toList();
  List<ClientBon> allBons;
  try {
    allBons = await ref.watch(_allClientBonsStreamProvider.future);
  } catch (_) {
    allBons = const <ClientBon>[];
  }
  final progresses = await Future.wait(progressFutures);
  final now = DateTime.now();
  // Group active bons by (merchantId, kind) for O(1) lookup. We
  // include 'expired' bons in the bookkeeping so the UI doesn't
  // re-introduce them via the fallback path — but we DON'T return
  // expired entries (they belong in a future "historique" view).
  final activeBonByKey = <String, ClientBon>{};
  final knownBonKeys = <String>{};
  String key(String merchantId, ClientBonKind k) =>
      '${merchantId}__${k.name}';
  for (final b in allBons) {
    knownBonKeys.add(key(b.merchantId, b.kind));
    final status = b.statusAt(now);
    if (status == ClientBonStatus.redeemed ||
        status == ClientBonStatus.expired) {
      continue;
    }
    activeBonByKey[key(b.merchantId, b.kind)] = b;
  }

  final rewards = <ClientRewardItem>[];

  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final progress = progresses[i];
    final welcomeGift = entry.merchant.welcomeGiftDescription?.trim() ?? '';
    final welcomeKey = key(entry.merchantId, ClientBonKind.welcome);
    final milestoneKey = key(entry.merchantId, ClientBonKind.milestone);

    // ── Welcome bon ────────────────────────────────────────────────────────
    final persistedWelcome = activeBonByKey[welcomeKey];
    if (persistedWelcome != null) {
      rewards.add(ClientRewardItem(
        merchant: entry.merchant,
        kind: ClientRewardKind.welcome,
        title: 'Bon de bienvenue',
        description: persistedWelcome.description,
        actionable: true,
        validUntilAt: persistedWelcome.validUntilAt,
        rewardKind: entry.config.rewardKind,
      ));
    } else if (!knownBonKeys.contains(welcomeKey) &&
        progress.hasFirstVisit &&
        !progress.welcomeBonClaimed &&
        welcomeGift.isNotEmpty) {
      // Legacy fallback — no doc was ever issued for this merchant.
      rewards.add(ClientRewardItem(
        merchant: entry.merchant,
        kind: ClientRewardKind.welcome,
        title: 'Bon de bienvenue',
        description: welcomeGift,
        actionable: true,
        rewardKind: entry.config.rewardKind,
      ));
    }

    // ── Milestone bon ──────────────────────────────────────────────────────
    final persistedMilestone = activeBonByKey[milestoneKey];
    if (persistedMilestone != null) {
      rewards.add(ClientRewardItem(
        merchant: entry.merchant,
        kind: ClientRewardKind.milestone,
        title: 'Bon fidélité disponible',
        description: persistedMilestone.description,
        actionable: false,
        validUntilAt: persistedMilestone.validUntilAt,
        rewardKind: entry.config.rewardKind,
      ));
    } else if (!knownBonKeys.contains(milestoneKey) &&
        entry.isRewardAvailable(progress)) {
      // Legacy fallback — pre-CF user above threshold without a doc.
      rewards.add(ClientRewardItem(
        merchant: entry.merchant,
        kind: ClientRewardKind.milestone,
        title: 'Bon fidélité disponible',
        description: entry.rewardLabel(),
        actionable: false,
        rewardKind: entry.config.rewardKind,
      ));
    }
  }

  // Welcome bons first (the most "delightful" reveal), then milestones.
  // Within a kind, soonest-to-expire first so the user is nudged to use
  // bons before they vanish; evergreen bons sink to the bottom.
  rewards.sort((a, b) {
    if (a.kind != b.kind) {
      return a.kind == ClientRewardKind.welcome ? -1 : 1;
    }
    final av = a.validUntilAt;
    final bv = b.validUntilAt;
    if (av != null && bv != null) {
      final cmp = av.compareTo(bv);
      if (cmp != 0) return cmp;
    } else if (av != null) {
      return -1;
    } else if (bv != null) {
      return 1;
    }
    final an = a.merchant.displayName ?? a.merchant.name;
    final bn = b.merchant.displayName ?? b.merchant.name;
    return an.toLowerCase().compareTo(bn.toLowerCase());
  });

  return rewards;
});
