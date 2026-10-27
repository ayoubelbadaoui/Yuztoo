import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/infrastructure/firestore_field_readers.dart';

import '../../domain/entities/active_notification.dart';

/// DTO for auto-notification in Firestore. Path: merchants/{merchantId}/auto_notifications/{id}
class AutoNotificationDto {
  const AutoNotificationDto({
    required this.id,
    required this.merchantId,
    required this.text,
    required this.trigger,
    required this.audience,
    required this.isEnabled,
    this.targetSegments = const [],
    this.createdAt,
    this.sentCount = 0,
    this.lastSentAt,
  });

  final String id;
  final String merchantId;
  final String text;
  final String trigger;
  final String audience;
  final List<String> targetSegments;
  final bool isEnabled;
  final DateTime? createdAt;
  final int sentCount;
  final DateTime? lastSentAt;

  static AutoNotificationDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String merchantId,
  ) {
    final data = doc.data();
    if (data == null) throw Exception('Document data is null');

    DateTime? parseTimestamp(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return AutoNotificationDto(
      id: doc.id,
      merchantId: merchantId,
      text: fsString(data['text']) ?? '',
      trigger: fsString(data['trigger']) ?? 'Date anniversaire client',
      audience: fsString(data['audience']) ?? 'Tous mes clients',
      targetSegments: data['target_segments'] is List
          ? fsStringList(data['target_segments'])
          : const [],
      isEnabled: fsBool(data['is_enabled']) ?? true,
      createdAt: parseTimestamp(data['created_at']),
      sentCount: fsNum(data['sent_count'])?.toInt() ?? 0,
      lastSentAt: parseTimestamp(data['last_sent_at']),
    );
  }

  ActiveNotification toDomain() => ActiveNotification(
        id: id,
        merchantId: merchantId,
        text: text,
        trigger: trigger,
        audience: audience,
        targetSegments: targetSegments,
        isEnabled: isEnabled,
        createdAt: createdAt,
        sentCount: sentCount,
        lastSentAt: lastSentAt,
      );

  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'text': text,
        'trigger': trigger,
        'audience': audience,
        'target_segments': targetSegments,
        'is_enabled': isEnabled,
        'created_at': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
}
