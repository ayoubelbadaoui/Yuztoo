import 'package:equatable/equatable.dart';

/// Lifecycle states for a persisted reward bon.
enum ClientBonStatus {
  /// Bon is unredeemed and at least 4 days from expiry (or evergreen).
  active,

  /// Bon expires in ≤3 days. Set by the daily scheduled CF when it
  /// fires the "expire bientôt" push (notified_expiring_at is set), and
  /// also derived locally from valid_until_at vs now() so the UI shows
  /// the warning state immediately even if the CF hasn't run yet.
  expiringSoon,

  /// Bon's valid_until_at is in the past. Hidden from "Mes avantages"
  /// by default — surfaced only in a future "historique" view.
  expired,

  /// Bon was honored (welcome: client tapped Utiliser; milestone:
  /// merchant decremented validated_passages). Hidden from active list.
  redeemed,
}

enum ClientBonKind {
  welcome,
  milestone,
}

/// Persisted reward bon issued by the Cloud Function on first_visit
/// (welcome) or on threshold-cross (milestone). Lives at
/// `users/{clientId}/loyalty_bons/{bonId}`. Server-only writes.
class ClientBon extends Equatable {
  const ClientBon({
    required this.id,
    required this.merchantId,
    required this.kind,
    required this.description,
    required this.issuedAt,
    this.validUntilAt,
    this.redeemedAt,
    this.notifiedExpiringAt,
    this.notifiedExpiredAt,
  });

  final String id;
  final String merchantId;
  final ClientBonKind kind;

  /// Snapshot at issuance — survives merchant-side config edits so the
  /// historical record stays coherent.
  final String description;

  final DateTime issuedAt;

  /// Null when the merchant did not enable validity (evergreen bon).
  final DateTime? validUntilAt;
  final DateTime? redeemedAt;
  final DateTime? notifiedExpiringAt;
  final DateTime? notifiedExpiredAt;

  /// Derived status from the timestamps. Computed locally so the UI
  /// reflects "expiring soon" / "expired" without waiting on the
  /// scheduled CF to set the notified_*_at markers.
  ClientBonStatus statusAt(DateTime now) {
    if (redeemedAt != null) return ClientBonStatus.redeemed;
    final until = validUntilAt;
    if (until == null) return ClientBonStatus.active;
    if (!now.isBefore(until)) return ClientBonStatus.expired;
    final daysLeft = until.difference(now).inDays;
    if (daysLeft <= 3) return ClientBonStatus.expiringSoon;
    return ClientBonStatus.active;
  }

  /// Days remaining until expiry, floored at 0. Returns null for
  /// evergreen bons (no countdown to show).
  int? daysLeftAt(DateTime now) {
    final until = validUntilAt;
    if (until == null) return null;
    final diff = until.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        merchantId,
        kind,
        description,
        issuedAt,
        validUntilAt,
        redeemedAt,
        notifiedExpiringAt,
        notifiedExpiredAt,
      ];
}
