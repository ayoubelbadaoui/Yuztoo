import 'package:equatable/equatable.dart';

/// Type of in-app notification sent to a client.
enum ClientNotificationType {
  /// A merchant published or activated a promotion.
  promotion,

  /// A loyalty reward was unlocked.
  loyalty,

  /// A merchant's auto-notification (rappel) triggered.
  auto,

  /// A persisted loyalty bon will expire within ≤3 days. Issued by the
  /// dailyBonExpirationScan CF. Tapping should route to "Mes avantages"
  /// so the client can use the bon before it lapses.
  bonExpiring,

  /// A persisted loyalty bon has lapsed. Issued by the same scan. Tap
  /// also routes to Mes avantages so the client can see the bon move
  /// to the historique state.
  bonExpired,
}

/// An in-app notification delivered to a client's inbox.
///
/// Stored at Firestore path: `users/{clientId}/notifications/{id}`.
class ClientNotification extends Equatable {
  const ClientNotification({
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
  final ClientNotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  /// Set when [type] is [ClientNotificationType.promotion].
  final String? promotionId;

  /// Links back to `merchants/{id}/sent_notifications/{id}` for open stats.
  final String? sentNotificationId;

  ClientNotification copyWith({
    String? id,
    String? clientId,
    String? merchantId,
    String? merchantName,
    ClientNotificationType? type,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
    String? promotionId,
    String? sentNotificationId,
  }) {
    return ClientNotification(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      promotionId: promotionId ?? this.promotionId,
      sentNotificationId: sentNotificationId ?? this.sentNotificationId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        merchantId,
        merchantName,
        type,
        title,
        body,
        isRead,
        createdAt,
        promotionId,
        sentNotificationId,
      ];
}
