import 'package:equatable/equatable.dart';

/// Canonical passage-based segment. Mirrors Cloud Functions `computeSegment`.
///
/// Computation order (same thresholds everywhere):
///   daysSinceLastVisit > 60  → inactif  (recency check first)
///   validatedPassages >= 10  → vip
///   validatedPassages >= 3   → habitue
///   otherwise                → nouveau
///
/// `abonne` is kept in the enum for legacy color/label mappings but is no
/// longer produced by [MerchantClientRow.segment].
enum ClientSegment {
  nouveau,
  vip,
  habitue,
  abonne,
  inactif;

  String get label {
    switch (this) {
      case ClientSegment.nouveau:
        return 'Nouveau';
      case ClientSegment.vip:
        return 'VIP';
      case ClientSegment.habitue:
        return 'Habitué';
      case ClientSegment.abonne:
        return 'Abonné';
      case ClientSegment.inactif:
        return 'Inactif';
    }
  }
}

/// A single client row in the merchant CRM list.
class MerchantClientRow extends Equatable {
  const MerchantClientRow({
    required this.clientUid,
    this.displayName,
    this.city,
    this.followedAt,
    this.heartLevel = 1,
    this.validatedPassages = 0,
    this.lastVisitAt,
  });

  final String clientUid;
  final String? displayName;
  final String? city;
  final DateTime? followedAt;

  /// Heart level set by the merchant (1–3). Kept for display only.
  /// Does NOT drive segment computation — use [validatedPassages] for that.
  final int heartLevel;

  /// Validated loyalty passages from merchants/{id}/loyalty_clients/{clientId}.
  final int validatedPassages;

  /// Last loyalty visit timestamp. Null if the client has never visited.
  final DateTime? lastVisitAt;

  /// Passage-based segment, consistent with Cloud Functions and notification
  /// targeting. Falls back to [followedAt] when no loyalty doc exists so that
  /// long-time followers with 0 visits are classified as [ClientSegment.inactif].
  ClientSegment get segment {
    final reference = lastVisitAt ?? followedAt;
    final daysSince = reference != null
        ? DateTime.now().difference(reference).inDays
        : 999;

    if (daysSince > 60) return ClientSegment.inactif;
    if (validatedPassages >= 10) return ClientSegment.vip;
    if (validatedPassages >= 3) return ClientSegment.habitue;
    return ClientSegment.nouveau;
  }

  String get displayLabel =>
      displayName?.isNotEmpty == true
          ? displayName!
          : '…${clientUid.substring(clientUid.length > 8 ? clientUid.length - 8 : 0)}';

  @override
  List<Object?> get props => <Object?>[
        clientUid,
        displayName,
        city,
        followedAt,
        heartLevel,
        validatedPassages,
        lastVisitAt,
      ];
}
