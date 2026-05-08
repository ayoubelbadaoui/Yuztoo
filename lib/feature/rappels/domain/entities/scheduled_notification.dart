import 'package:equatable/equatable.dart';

/// Lifecycle states for a scheduled merchant notification.
enum ScheduledNotificationStatus {
  /// Waiting for the scheduled tick. Cancellable by the owner.
  pending,

  /// Promoted by the scheduling CF — followers received the push.
  /// `sent_at` is populated on the doc.
  sent,

  /// Owner cancelled before the tick. Will not be sent.
  cancelled,

  /// CF tried to send but the merchant was over-quota at tick time, or
  /// some other guard rejected the send. The doc is left in this
  /// state for visibility — the merchant can re-schedule manually.
  failed,
}

/// Scheduled manual notification. Lives at
/// `merchants/{merchantId}/scheduled_notifications/{id}` and is processed
/// by the daily-tick CF (`processScheduledNotifications`) which fans out
/// the same way as the immediate quick-send path.
class ScheduledNotification extends Equatable {
  const ScheduledNotification({
    required this.id,
    required this.text,
    required this.audience,
    required this.segments,
    required this.scheduledAt,
    required this.status,
    this.createdAt,
    this.createdByUid,
    this.sentAt,
    this.sentCount,
    this.failureReason,
  });

  final String id;
  final String text;
  final String audience;
  final List<String> segments;

  /// When the CF should pick this up and fan out. UTC instant — the
  /// tick CF runs every 5 minutes Europe/Paris but compares on absolute
  /// time, not local clock.
  final DateTime scheduledAt;

  final ScheduledNotificationStatus status;
  final DateTime? createdAt;

  /// UID of the merchant owner that scheduled this — useful for audit
  /// trails when a merchant has a multi-user setup later.
  final String? createdByUid;

  /// Populated when status transitions to `sent`.
  final DateTime? sentAt;
  final int? sentCount;

  /// Populated when status transitions to `failed` — short reason
  /// string ("quota_exceeded", "no_followers", …) so the UI can
  /// explain why.
  final String? failureReason;

  bool get isPending => status == ScheduledNotificationStatus.pending;

  ScheduledNotification copyWith({
    String? id,
    String? text,
    String? audience,
    List<String>? segments,
    DateTime? scheduledAt,
    ScheduledNotificationStatus? status,
    DateTime? createdAt,
    String? createdByUid,
    DateTime? sentAt,
    int? sentCount,
    String? failureReason,
  }) {
    return ScheduledNotification(
      id: id ?? this.id,
      text: text ?? this.text,
      audience: audience ?? this.audience,
      segments: segments ?? this.segments,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdByUid: createdByUid ?? this.createdByUid,
      sentAt: sentAt ?? this.sentAt,
      sentCount: sentCount ?? this.sentCount,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        text,
        audience,
        segments,
        scheduledAt,
        status,
        createdAt,
        createdByUid,
        sentAt,
        sentCount,
        failureReason,
      ];
}
