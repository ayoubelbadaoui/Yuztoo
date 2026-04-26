import 'package:equatable/equatable.dart';

/// Segment computed from heart level and follow recency.
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
  });

  final String clientUid;
  final String? displayName;
  final String? city;
  final DateTime? followedAt;

  /// Heart level set by the client (1–3).
  final int heartLevel;

  ClientSegment get segment {
    if (heartLevel >= 3) return ClientSegment.vip;
    if (heartLevel >= 2) return ClientSegment.habitue;
    final now = DateTime.now();
    if (followedAt != null &&
        now.difference(followedAt!).inDays < 14) {
      return ClientSegment.nouveau;
    }
    if (followedAt != null &&
        now.difference(followedAt!).inDays > 60 &&
        heartLevel < 2) {
      return ClientSegment.inactif;
    }
    return ClientSegment.abonne;
  }

  String get displayLabel =>
      displayName?.isNotEmpty == true ? displayName! : '…${clientUid.substring(clientUid.length > 8 ? clientUid.length - 8 : 0)}';

  @override
  List<Object?> get props =>
      <Object?>[clientUid, displayName, city, followedAt, heartLevel];
}
