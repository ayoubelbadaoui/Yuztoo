import 'package:equatable/equatable.dart';

/// Merchant-configurable thresholds that drive client segment labels (VIP,
/// Habitué, etc.) and control whether clients can see their own tier.
class ClientGratificationConfig extends Equatable {
  const ClientGratificationConfig({
    this.nouveauLabel = 'Nouveau',
    this.habituelLabel = 'Habitué',
    this.vipLabel = 'VIP',
    this.habituelThreshold = 3,
    this.vipThreshold = 10,
    this.inactifAfterDays = 60,
    this.showTierToClient = true,
  });

  /// Label shown to the client and in the CRM for the first tier.
  final String nouveauLabel;

  /// Label for the intermediate tier (3…vipThreshold-1 passages by default).
  final String habituelLabel;

  /// Label for the top tier (≥ vipThreshold passages by default).
  final String vipLabel;

  /// Minimum validated passages to reach the "habituel" tier.
  final int habituelThreshold;

  /// Minimum validated passages to reach the "VIP" tier.
  final int vipThreshold;

  /// Days without a visit before a client is considered inactive.
  final int inactifAfterDays;

  /// When true, clients can see their tier label on the merchant storefront.
  final bool showTierToClient;

  static const ClientGratificationConfig defaults = ClientGratificationConfig();

  ClientGratificationConfig copyWith({
    String? nouveauLabel,
    String? habituelLabel,
    String? vipLabel,
    int? habituelThreshold,
    int? vipThreshold,
    int? inactifAfterDays,
    bool? showTierToClient,
  }) =>
      ClientGratificationConfig(
        nouveauLabel: nouveauLabel ?? this.nouveauLabel,
        habituelLabel: habituelLabel ?? this.habituelLabel,
        vipLabel: vipLabel ?? this.vipLabel,
        habituelThreshold: habituelThreshold ?? this.habituelThreshold,
        vipThreshold: vipThreshold ?? this.vipThreshold,
        inactifAfterDays: inactifAfterDays ?? this.inactifAfterDays,
        showTierToClient: showTierToClient ?? this.showTierToClient,
      );

  /// Deserialise from a Firestore map (e.g. `merchants/{id}.gratification_config`).
  factory ClientGratificationConfig.fromMap(Map<String, dynamic> map) =>
      ClientGratificationConfig(
        nouveauLabel: (map['nouveau_label'] as String?)?.trim().isNotEmpty == true
            ? map['nouveau_label'] as String
            : 'Nouveau',
        habituelLabel:
            (map['habituel_label'] as String?)?.trim().isNotEmpty == true
                ? map['habituel_label'] as String
                : 'Habitué',
        vipLabel: (map['vip_label'] as String?)?.trim().isNotEmpty == true
            ? map['vip_label'] as String
            : 'VIP',
        habituelThreshold: (map['habituel_threshold'] as int?) ?? 3,
        vipThreshold: (map['vip_threshold'] as int?) ?? 10,
        inactifAfterDays: (map['inactif_after_days'] as int?) ?? 60,
        showTierToClient: (map['show_tier_to_client'] as bool?) ?? true,
      );

  Map<String, dynamic> toMap() => {
        'nouveau_label': nouveauLabel,
        'habituel_label': habituelLabel,
        'vip_label': vipLabel,
        'habituel_threshold': habituelThreshold,
        'vip_threshold': vipThreshold,
        'inactif_after_days': inactifAfterDays,
        'show_tier_to_client': showTierToClient,
      };

  /// Passage-based segment key (`nouveau`, `habitue`, `vip`, `inactif`) using
  /// this merchant's thresholds — same order as CRM / notification ciblage.
  String segmentKeyFor({
    required int validatedPassages,
    required int daysSinceLastVisit,
  }) {
    if (daysSinceLastVisit > inactifAfterDays) return 'inactif';
    if (validatedPassages >= vipThreshold) return 'vip';
    if (validatedPassages >= habituelThreshold) return 'habitue';
    return 'nouveau';
  }

  /// Returns the custom tier label for a given passage count, using this
  /// merchant's configured thresholds and names instead of the hardcoded enum.
  String labelForPassages(int passages) {
    if (passages >= vipThreshold) return vipLabel;
    if (passages >= habituelThreshold) return habituelLabel;
    return nouveauLabel;
  }

  /// Label for [segmentKeyFor] output (inactive clients → fixed « Inactif »).
  String labelForSegmentKey(String segmentKey) {
    switch (segmentKey) {
      case 'vip':
        return vipLabel;
      case 'habitue':
        return habituelLabel;
      case 'inactif':
        return 'Inactif';
      default:
        return nouveauLabel;
    }
  }

  @override
  List<Object?> get props => [
        nouveauLabel,
        habituelLabel,
        vipLabel,
        habituelThreshold,
        vipThreshold,
        inactifAfterDays,
        showTierToClient,
      ];
}
