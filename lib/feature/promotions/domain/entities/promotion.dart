/// Client type / offer tier for a promotion.
enum ClientType { gratuit, premium, payant }

extension ClientTypeX on ClientType {
  String get value => switch (this) {
        ClientType.gratuit => 'gratuit',
        ClientType.premium => 'premium',
        ClientType.payant => 'payant',
      };
  static ClientType fromString(String? v) {
    switch (v) {
      case 'premium':
        return ClientType.premium;
      case 'payant':
        return ClientType.payant;
      default:
        return ClientType.gratuit;
    }
  }
}

/// Geographic broadcast zone for payant promotions.
enum PromotionZone { ville, quartier, proche }

extension PromotionZoneX on PromotionZone {
  String get value => switch (this) {
        PromotionZone.ville => 'ville',
        PromotionZone.quartier => 'quartier',
        PromotionZone.proche => 'proche',
      };

  String get label => switch (this) {
        PromotionZone.ville => 'Villes',
        PromotionZone.quartier => 'Quartier',
        PromotionZone.proche => 'Proche de vous',
      };

  int get estimatedReach => switch (this) {
        PromotionZone.ville => 500,
        PromotionZone.quartier => 200,
        PromotionZone.proche => 100,
      };

  static PromotionZone? fromString(String? v) {
    switch (v) {
      case 'ville':
        return PromotionZone.ville;
      case 'quartier':
        return PromotionZone.quartier;
      case 'proche':
        return PromotionZone.proche;
      default:
        return null;
    }
  }
}

/// Promotion entity.
class Promotion {
  const Promotion({
    required this.id,
    required this.merchantId,
    required this.title,
    required this.subtitle,
    required this.dateFrom,
    required this.dateTo,
    required this.selectedClientType,
    required this.isOnline,
    this.imagePath,
    this.imageUrl,
    this.viewCount = 0,
    this.targetSegments = const [],
    this.diffusionZone,
  });

  final String id;
  final String merchantId;
  final String title;
  final String subtitle;
  final DateTime dateFrom;
  final DateTime dateTo;
  final ClientType selectedClientType;
  final bool isOnline;
  /// Local file path (when picked, before upload).
  final String? imagePath;
  /// Storage URL after upload (persisted in Firestore).
  final String? imageUrl;
  /// Number of times clients have viewed this promotion.
  final int viewCount;
  /// Targeted CRM segments for premium promos (values: 'vip', 'soutien', 'habitue').
  final List<String> targetSegments;
  /// Geographic broadcast zone for payant promos.
  final PromotionZone? diffusionZone;

  Promotion copyWith({
    String? id,
    String? merchantId,
    String? title,
    String? subtitle,
    DateTime? dateFrom,
    DateTime? dateTo,
    ClientType? selectedClientType,
    bool? isOnline,
    String? imagePath,
    String? imageUrl,
    int? viewCount,
    List<String>? targetSegments,
    PromotionZone? diffusionZone,
  }) =>
      Promotion(
        id: id ?? this.id,
        merchantId: merchantId ?? this.merchantId,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        dateFrom: dateFrom ?? this.dateFrom,
        dateTo: dateTo ?? this.dateTo,
        selectedClientType: selectedClientType ?? this.selectedClientType,
        isOnline: isOnline ?? this.isOnline,
        imagePath: imagePath ?? this.imagePath,
        imageUrl: imageUrl ?? this.imageUrl,
        viewCount: viewCount ?? this.viewCount,
        targetSegments: targetSegments ?? this.targetSegments,
        diffusionZone: diffusionZone ?? this.diffusionZone,
      );
}

