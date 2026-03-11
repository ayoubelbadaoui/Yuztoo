/// Client type for a promotion.
enum ClientType { gratuit, premium, payant }

/// Promotion entity.
class Promotion {
  const Promotion({
    required this.title,
    required this.subtitle,
    required this.dateFrom,
    required this.dateTo,
    required this.selectedClientType,
    required this.isOnline,
    this.imagePath,
  });

  final String title;
  final String subtitle;
  final DateTime dateFrom;
  final DateTime dateTo;
  final ClientType selectedClientType;
  final bool isOnline;
  final String? imagePath;

  Promotion copyWith({
    bool? isOnline,
    ClientType? clientType,
    String? imagePath,
  }) =>
      Promotion(
        title: title,
        subtitle: subtitle,
        dateFrom: dateFrom,
        dateTo: dateTo,
        selectedClientType: clientType ?? selectedClientType,
        isOnline: isOnline ?? this.isOnline,
        imagePath: imagePath ?? this.imagePath,
      );
}

