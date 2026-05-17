import 'package:equatable/equatable.dart';

import '../../../merchant/domain/entities/client_gratification_config.dart';

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

  static ClientSegment fromSegmentKey(String key) {
    switch (key) {
      case 'vip':
        return ClientSegment.vip;
      case 'habitue':
        return ClientSegment.habitue;
      case 'inactif':
        return ClientSegment.inactif;
      case 'abonne':
        return ClientSegment.abonne;
      default:
        return ClientSegment.nouveau;
    }
  }
}

/// A single client row in the merchant CRM list.
class MerchantClientRow extends Equatable {
  const MerchantClientRow({
    required this.clientUid,
    this.displayName,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.city,
    this.followedAt,
    this.heartLevel = 1,
    this.validatedPassages = 0,
    this.lastVisitAt,
    this.manualSegment,
    this.gratificationConfig,
  });

  final String clientUid;
  final String? displayName;

  /// Separate name parts persisted under `users/{uid}.first_name` and
  /// `users/{uid}.last_name`. Used as a fallback for [displayLabel] when the
  /// composite `displayName` field hasn't been written yet (legacy accounts
  /// that completed only the early signup step).
  final String? firstName;
  final String? lastName;

  /// Avatar URL from the client's Firebase Auth / Firestore profile. Null when
  /// the client has not uploaded a photo — UI falls back to a circle of
  /// initials so the list is always renderable.
  final String? photoUrl;
  final String? city;
  final DateTime? followedAt;

  /// Heart level set by the merchant (1–3). Kept for display only.
  /// Does NOT drive segment computation — use [validatedPassages] for that.
  final int heartLevel;

  /// Validated loyalty passages from merchants/{id}/loyalty_clients/{clientId}.
  final int validatedPassages;

  /// Last loyalty visit timestamp. Null if the client has never visited.
  final DateTime? lastVisitAt;

  /// Manual segment set by the merchant from the client detail sheet. Stored
  /// at `merchants/{merchantId}/clients/{clientUid}.manual_segment`. When
  /// non-null this overrides the auto-computed segment so the merchant can
  /// label a long-standing customer as VIP even before they hit 10 passages.
  final ClientSegment? manualSegment;

  /// Merchant gratification thresholds; [ClientGratificationConfig.defaults]
  /// when null.
  final ClientGratificationConfig? gratificationConfig;

  /// Passage-based segment, consistent with Cloud Functions and notification
  /// targeting. Falls back to [followedAt] when no loyalty doc exists so that
  /// long-time followers with 0 visits are classified as [ClientSegment.inactif].
  ///
  /// If [manualSegment] is non-null the merchant has explicitly set a label
  /// for this client — that overrides the auto-computation.
  ClientSegment get segment {
    final manual = manualSegment;
    if (manual != null) return manual;
    return autoSegment;
  }

  /// Pure auto-computed segment ignoring any manual override. Useful when the
  /// UI wants to surface the "real" passage-based status alongside a manual
  /// tag.
  ClientSegment get autoSegment {
    final grat = gratificationConfig ?? ClientGratificationConfig.defaults;
    final reference = lastVisitAt ?? followedAt;
    final daysSince = reference != null
        ? DateTime.now().difference(reference).inDays
        : 999;
    return ClientSegment.fromSegmentKey(
      grat.segmentKeyFor(
        validatedPassages: validatedPassages,
        daysSinceLastVisit: daysSince,
      ),
    );
  }

  /// Best human-readable label for the client. Tries, in order:
  ///   1. The composite `displayName`
  ///   2. `'firstName lastName'` when both parts are set
  ///   3. Just `firstName` or just `lastName` if only one is set
  ///   4. The literal string `'Client'` (used to be a truncated UID — that
  ///      leaks an internal ID into the merchant UI for no benefit).
  String get displayLabel {
    final dn = displayName?.trim() ?? '';
    if (dn.isNotEmpty) return dn;
    final fn = firstName?.trim() ?? '';
    final ln = lastName?.trim() ?? '';
    if (fn.isNotEmpty && ln.isNotEmpty) return '$fn $ln';
    if (fn.isNotEmpty) return fn;
    if (ln.isNotEmpty) return ln;
    return 'Client';
  }

  @override
  List<Object?> get props => <Object?>[
        clientUid,
        displayName,
        firstName,
        lastName,
        photoUrl,
        city,
        followedAt,
        heartLevel,
        validatedPassages,
        lastVisitAt,
        manualSegment,
        gratificationConfig,
      ];
}
