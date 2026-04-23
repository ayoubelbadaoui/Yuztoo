/// Data holder for an active auto-notification (persisted in Firestore).
class ActiveNotification {
  const ActiveNotification({
    required this.id,
    required this.merchantId,
    required this.text,
    this.trigger = 'Date anniversaire client',
    this.audience = 'Tous mes clients',
    this.targetSegments = const [],
    this.isEnabled = true,
    this.createdAt,
    this.sentCount = 0,
    this.lastSentAt,
  });

  final String id;
  final String merchantId;
  final String text;
  final String trigger;
  final String audience;

  /// Targeted CRM segments when [audience] == 'Certains clients'.
  /// Values: 'vip', 'habitue', 'nouveau', 'abonne'.
  final List<String> targetSegments;
  final bool isEnabled;
  final DateTime? createdAt;

  /// Number of times this auto-notification has been fired (updated by Cloud Function).
  final int sentCount;

  /// When this notification was last triggered.
  final DateTime? lastSentAt;

  ActiveNotification copyWith({
    String? id,
    String? merchantId,
    String? text,
    String? trigger,
    String? audience,
    List<String>? targetSegments,
    bool? isEnabled,
    DateTime? createdAt,
    int? sentCount,
    DateTime? lastSentAt,
  }) {
    return ActiveNotification(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      text: text ?? this.text,
      trigger: trigger ?? this.trigger,
      audience: audience ?? this.audience,
      targetSegments: targetSegments ?? this.targetSegments,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      sentCount: sentCount ?? this.sentCount,
      lastSentAt: lastSentAt ?? this.lastSentAt,
    );
  }
}

