import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/promotion.dart';

/// DTO for Promotion in Firestore.
/// Path: merchants/{merchantId}/promotions/{promoId}
class PromotionDto {
  const PromotionDto({
    required this.id,
    required this.merchantId,
    required this.title,
    required this.subtitle,
    required this.dateFrom,
    required this.dateTo,
    required this.clientType,
    required this.isOnline,
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
  final String clientType;
  final bool isOnline;
  final String? imageUrl;
  final int viewCount;
  /// Segment keys for premium promos (e.g. ['vip', 'habitue']).
  final List<String> targetSegments;
  /// Zone key for payant promos (e.g. 'ville', 'quartier', 'proche').
  final String? diffusionZone;

  static PromotionDto? fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String merchantId,
  ) {
    final data = doc.data();
    if (data == null) return null;

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.now();
    }

    List<String> parseSegments(dynamic v) {
      if (v == null) return const [];
      if (v is! List) return const [];
      return v.whereType<String>().toList();
    }

    return PromotionDto(
      id: doc.id,
      merchantId: merchantId,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      dateFrom: parseDate(data['date_from']),
      dateTo: parseDate(data['date_to']),
      clientType: data['client_type'] as String? ?? 'gratuit',
      isOnline: data['is_online'] as bool? ?? false,
      imageUrl: data['image_url'] as String?,
      viewCount: (data['view_count'] as num?)?.toInt() ?? 0,
      targetSegments: parseSegments(data['target_segments']),
      diffusionZone: data['diffusion_zone'] as String?,
    );
  }

  Promotion toDomain() => Promotion(
        id: id,
        merchantId: merchantId,
        title: title,
        subtitle: subtitle,
        dateFrom: dateFrom,
        dateTo: dateTo,
        selectedClientType: ClientTypeX.fromString(clientType),
        isOnline: isOnline,
        imageUrl: imageUrl,
        viewCount: viewCount,
        targetSegments: targetSegments,
        diffusionZone: PromotionZoneX.fromString(diffusionZone),
      );

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'subtitle': subtitle,
        'date_from': Timestamp.fromDate(dateFrom),
        'date_to': Timestamp.fromDate(dateTo),
        'client_type': clientType,
        'is_online': isOnline,
        if (imageUrl != null) 'image_url': imageUrl,
        'target_segments': targetSegments,
        if (diffusionZone != null) 'diffusion_zone': diffusionZone,
      };
}
