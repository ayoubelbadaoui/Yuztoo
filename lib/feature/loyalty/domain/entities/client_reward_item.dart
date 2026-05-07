import 'package:equatable/equatable.dart';

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
/// Computed on the fly from the loyalty doc + merchant config — there is no
/// dedicated "rewards" subcollection in v1. See
/// [availableClientRewardsProvider] for how these are produced.
class ClientRewardItem extends Equatable {
  const ClientRewardItem({
    required this.merchant,
    required this.kind,
    required this.title,
    required this.description,
    required this.actionable,
  });

  final Merchant merchant;
  final ClientRewardKind kind;

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

  @override
  List<Object?> get props => <Object?>[
        merchant.id,
        kind,
        title,
        description,
        actionable,
      ];
}
