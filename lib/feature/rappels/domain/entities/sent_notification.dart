import 'package:equatable/equatable.dart';

/// A notification manually composed and sent by the merchant to their clients.
///
/// Stored at: `merchants/{merchantId}/sent_notifications/{id}`.
class SentNotification extends Equatable {
  const SentNotification({
    required this.id,
    required this.merchantId,
    required this.text,
    required this.audience,
    required this.sentCount,
    required this.sentAt,
    this.segments = const [],
    this.openCount = 0,
  });

  final String id;
  final String merchantId;
  final String text;

  /// 'Tous mes clients' or 'Certains clients'.
  final String audience;

  /// Segment keys targeted (empty = all followers).
  final List<String> segments;

  /// Number of clients who received the notification.
  final int sentCount;

  /// Inbox opens (client marked as read) — mirrors promotion [viewCount].
  final int openCount;

  final DateTime sentAt;

  SentNotification copyWith({
    String? id,
    String? merchantId,
    String? text,
    String? audience,
    List<String>? segments,
    int? sentCount,
    int? openCount,
    DateTime? sentAt,
  }) =>
      SentNotification(
        id: id ?? this.id,
        merchantId: merchantId ?? this.merchantId,
        text: text ?? this.text,
        audience: audience ?? this.audience,
        segments: segments ?? this.segments,
        sentCount: sentCount ?? this.sentCount,
        openCount: openCount ?? this.openCount,
        sentAt: sentAt ?? this.sentAt,
      );

  @override
  List<Object?> get props =>
      [id, merchantId, text, audience, segments, sentCount, openCount, sentAt];
}
