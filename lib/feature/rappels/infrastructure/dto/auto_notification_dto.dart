import 'package:cloud_firestore/cloud_firestore.dart';

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
    this.createdAt,
  });

  final String id;
  final String merchantId;
  final String text;
  final String trigger;
  final String audience;
  final bool isEnabled;
  final DateTime? createdAt;

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
      text: data['text'] as String? ?? '',
      trigger: data['trigger'] as String? ?? 'Date anniversaire client',
      audience: data['audience'] as String? ?? 'Tous mes clients',
      isEnabled: data['is_enabled'] as bool? ?? true,
      createdAt: parseTimestamp(data['created_at']),
    );
  }

  ActiveNotification toDomain() => ActiveNotification(
        id: id,
        merchantId: merchantId,
        text: text,
        trigger: trigger,
        audience: audience,
        isEnabled: isEnabled,
        createdAt: createdAt,
      );

  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'text': text,
        'trigger': trigger,
        'audience': audience,
        'is_enabled': isEnabled,
        'created_at': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
}
