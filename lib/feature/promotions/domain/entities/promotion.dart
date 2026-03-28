/// Client type for a promotion.
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
      );
}

