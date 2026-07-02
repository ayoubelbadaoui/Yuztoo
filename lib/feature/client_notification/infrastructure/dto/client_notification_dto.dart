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
///   "sent_notification_id": "..." | null,
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
    this.sentNotificationId,
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
  final String? sentNotificationId;

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
      sentNotificationId: data['sent_notification_id'] as String?,
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
        if (sentNotificationId != null)
          'sent_notification_id': sentNotificationId,
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
        sentNotificationId: sentNotificationId,
      );

  // Wire vocabulary lives here AND on the CF side
  // (functions/src/index.ts: dailyBonExpirationScan writes type
  // 'bon_expiring' / 'bon_expired'). Keep these maps in lockstep — a
  // drift here means the bon-tap deep-link silently falls through to
  // the merchant-storefront branch.
  static String typeToString(ClientNotificationType t) => switch (t) {
        ClientNotificationType.promotion => 'promotion',
        ClientNotificationType.loyalty => 'loyalty',
        ClientNotificationType.auto => 'auto',
        ClientNotificationType.bonExpiring => 'bon_expiring',
        ClientNotificationType.bonExpired => 'bon_expired',
      };

  static ClientNotificationType _typeFromString(String s) => switch (s) {
        'promotion' => ClientNotificationType.promotion,
        'loyalty' => ClientNotificationType.loyalty,
        'auto' => ClientNotificationType.auto,
        'general' => ClientNotificationType.auto,
        'bon_expiring' => ClientNotificationType.bonExpiring,
        'bon_expired' => ClientNotificationType.bonExpired,
        // Unknown future wire values: treat as generic merchant alert (tap →
        // storefront), not as promotion — mis-classifying breaks inbox routing.
        _ => ClientNotificationType.auto,
      };
}
