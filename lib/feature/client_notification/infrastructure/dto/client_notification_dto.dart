import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/client_notification.dart';

/// Firestore ↔ [ClientNotification] mapper.
///
/// Document shape (at `users/{clientId}/notifications/{id}`):
/// ```json
/// {
///   "merchant_id":   "...",
///   "merchant_name": "...",
///   "type":          "promotion" | "loyalty" | "auto",
///   "title":         "...",
///   "body":          "...",
///   "is_read":       false,
///   "promotion_id":  "..." | null,
///   "created_at":    <Timestamp>
/// }
/// ```
class ClientNotificationDto {
  const ClientNotificationDto({
    required this.id,
    required this.clientId,
    required this.merchantId,
    required this.merchantName,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.promotionId,
  });

  final String id;
  final String clientId;
  final String merchantId;
  final String merchantName;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? promotionId;

  factory ClientNotificationDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String clientId,
  ) {
    final data = doc.data() ?? {};
    final ts = data['created_at'];
    final created = ts is Timestamp
        ? ts.toDate()
        : DateTime.now();

    return ClientNotificationDto(
      id: doc.id,
      clientId: clientId,
      merchantId: (data['merchant_id'] as String?) ?? '',
      merchantName: (data['merchant_name'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'general',
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      isRead: (data['is_read'] as bool?) ?? false,
      createdAt: created,
      promotionId: data['promotion_id'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'merchant_id': merchantId,
        'merchant_name': merchantName,
        'type': type,
        'title': title,
        'body': body,
        'is_read': isRead,
        'created_at': FieldValue.serverTimestamp(),
        if (promotionId != null) 'promotion_id': promotionId,
      };

  ClientNotification toDomain() => ClientNotification(
        id: id,
        clientId: clientId,
        merchantId: merchantId,
        merchantName: merchantName,
        type: _typeFromString(type),
        title: title,
        body: body,
        isRead: isRead,
        createdAt: createdAt,
        promotionId: promotionId,
      );

  static String typeToString(ClientNotificationType t) => switch (t) {
        ClientNotificationType.promotion => 'promotion',
        ClientNotificationType.loyalty => 'loyalty',
        ClientNotificationType.auto => 'auto',
      };

  static ClientNotificationType _typeFromString(String s) => switch (s) {
        'loyalty' => ClientNotificationType.loyalty,
        'auto' => ClientNotificationType.auto,
        _ => ClientNotificationType.promotion,
      };
}
