import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/infrastructure/firestore_field_readers.dart';

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
    this.openCount = 0,
  });

  final String id;
  final String merchantId;
  final String text;
  final String audience;
  final List<String> segments;
  final int sentCount;
  final int openCount;
  final DateTime sentAt;

  factory SentNotificationDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return SentNotificationDto(
      id: doc.id,
      merchantId: fsString(d['merchant_id']) ?? '',
      text: fsString(d['text']) ?? '',
      audience: fsString(d['audience']) ?? 'Tous mes clients',
      segments: d['segments'] is List
          ? fsStringList(d['segments'])
          : const [],
      sentCount: fsNum(d['sent_count'])?.toInt() ?? 0,
      openCount: fsNum(d['open_count'])?.toInt() ?? 0,
      sentAt: fsTimestamp(d['sent_at'])?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'merchant_id': merchantId,
        'text': text,
        'audience': audience,
        'segments': segments,
        'sent_count': sentCount,
        'open_count': openCount,
        'sent_at': FieldValue.serverTimestamp(),
      };

  SentNotification toDomain() => SentNotification(
        id: id,
        merchantId: merchantId,
        text: text,
        audience: audience,
        segments: segments,
        sentCount: sentCount,
        openCount: openCount,
        sentAt: sentAt,
      );
}
