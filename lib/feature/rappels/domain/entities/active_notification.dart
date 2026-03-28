/// Data holder for an active auto-notification (persisted in Firestore).
class ActiveNotification {
  const ActiveNotification({
    required this.id,
    required this.merchantId,
    required this.text,
    this.trigger = 'Date anniversaire client',
    this.audience = 'Tous mes clients',
    this.isEnabled = true,
    this.createdAt,
  });

  final String id;
  final String merchantId;
  final String text;
  final String trigger;
  final String audience;
  final bool isEnabled;
  final DateTime? createdAt;

  ActiveNotification copyWith({
    String? id,
    String? merchantId,
    String? text,
    String? trigger,
    String? audience,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return ActiveNotification(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      text: text ?? this.text,
      trigger: trigger ?? this.trigger,
      audience: audience ?? this.audience,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

