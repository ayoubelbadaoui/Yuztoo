import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/sent_notification.dart';

class SentNotificationDto {
  const SentNotificationDto({
    required this.id,
    required this.merchantId,
    required this.text,
    required this.audience,
    required this.segments,
    required this.sentCount,
    required this.sentAt,
  });

  final String id;
  final String merchantId;
  final String text;
  final String audience;
  final List<String> segments;
  final int sentCount;
  final DateTime sentAt;

  factory SentNotificationDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return SentNotificationDto(
      id: doc.id,
      merchantId: d['merchant_id'] as String? ?? '',
      text: d['text'] as String? ?? '',
      audience: d['audience'] as String? ?? 'Tous mes clients',
      segments: d['segments'] is List
          ? List<String>.from(d['segments'] as List)
          : const [],
      sentCount: d['sent_count'] as int? ?? 0,
      sentAt: (d['sent_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'merchant_id': merchantId,
        'text': text,
        'audience': audience,
        'segments': segments,
        'sent_count': sentCount,
        'sent_at': FieldValue.serverTimestamp(),
      };

  SentNotification toDomain() => SentNotification(
        id: id,
        merchantId: merchantId,
        text: text,
        audience: audience,
        segments: segments,
        sentCount: sentCount,
        sentAt: sentAt,
      );
}
