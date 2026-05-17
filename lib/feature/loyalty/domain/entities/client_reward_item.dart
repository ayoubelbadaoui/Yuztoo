import 'package:equatable/equatable.dart';

import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';

/// Origin of a redeemable bon shown in the client's "Mes avantages" view.
enum ClientRewardKind {
  /// Bon de bienvenue issued automatically on the client's first passage at
  /// the merchant. Claimable once. Expires only when the merchant clears or
  /// rotates their welcome gift configuration (out of scope for v1).
  welcome,

  /// Bon earned by reaching the loyalty milestone (validated_passages or
  /// cumulative_spend_euros crossing the configured threshold). Redemption
  /// happens via the existing merchant-side "Donner le bon" flow which
  /// decrements counters; the client side is purely informational for v1.
  milestone,
}

/// One redeemable bon belonging to the connected client at a given merchant.
///
/// Two backing sources, surfaced uniformly here:
///   1. Persisted `users/{uid}/loyalty_bons` doc issued by the Cloud
///      Function on first_visit / threshold cross. Carries
///      [validUntilAt] when the merchant enabled validity, so the UI
///      can show countdowns and the scheduled CF can warn / expire.
///   2. On-the-fly fallback for unmigrated merchants (no bon doc yet
///      because the CF was deployed after the user already crossed
///      the threshold or claimed first visit). [validUntilAt] is null
///      in this branch — bon stays evergreen for legacy users.
class ClientRewardItem extends Equatable {
  const ClientRewardItem({
    required this.merchant,
    required this.kind,
    required this.title,
    required this.description,
    required this.actionable,
    this.validUntilAt,
    this.rewardKind,
  });

  final Merchant merchant;
  final ClientRewardKind kind;

  /// Reward type for Mes avantages tabs (uses enrolled program when set).
  final LoyaltyRewardKind? rewardKind;

  /// Short headline shown on the carousel card. Examples:
  ///   - "Bon de bienvenue"
  ///   - "Bon fidélité disponible"
  final String title;

  /// One-line description shown under the title and on the detail sheet.
  /// For welcome bons this is `merchant.welcomeGiftDescription`; for
  /// milestone bons this is the merchant's reward label (e.g. "Bon d'achat
  /// 10 €").
  final String description;

  /// Whether this card has a client-side claim CTA.
  ///
  /// - Welcome bon: `true` — client taps "Utiliser" to claim immediately.
  /// - Milestone bon: `false` for v1 — claim is performed by the merchant
  ///   via "Donner le bon" in their Rappels screen, which decrements
  ///   counters (existing flow). The detail sheet shows a "Comment
  ///   l'utiliser" hint instead of a button.
  final bool actionable;

  /// Expiry instant. `null` for evergreen bons (legacy on-the-fly
  /// fallback OR merchants who haven't enabled validity).
  final DateTime? validUntilAt;

  /// Days remaining until expiry, floored at 0. `null` when there is
  /// no expiry (evergreen bon).
  int? daysLeftAt(DateTime now) {
    final until = validUntilAt;
    if (until == null) return null;
    final diff = until.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// True when the bon is within 3 days of expiring (matches the
  /// scheduled CF's "expire bientôt" threshold so client + server
  /// agree on what counts as "soon").
  bool isExpiringSoonAt(DateTime now) {
    final until = validUntilAt;
    if (until == null) return false;
    if (!now.isBefore(until)) return false;
    return until.difference(now).inDays <= 3;
  }

  @override
  List<Object?> get props => <Object?>[
        merchant.id,
        kind,
        title,
        description,
        actionable,
        validUntilAt,
        rewardKind,
      ];
}
