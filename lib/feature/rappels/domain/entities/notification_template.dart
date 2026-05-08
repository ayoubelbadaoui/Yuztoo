import 'package:equatable/equatable.dart';

/// Pre-saved manual notification template, owned by a merchant. Lets the
/// merchant compose once ("Promo de fin de semaine — -20% jusqu'à
/// dimanche soir") and re-send the same body in one tap from the rappels
/// screen, without retyping or losing audience/segment context.
///
/// Persisted at `merchants/{merchantId}/notification_templates/{templateId}`.
/// CRUD by the owning merchant only — Firestore rules enforce this.
class NotificationTemplate extends Equatable {
  const NotificationTemplate({
    required this.id,
    required this.name,
    required this.text,
    required this.audience,
    required this.segments,
    this.createdAt,
    this.updatedAt,
  });

  /// Empty id is reserved for not-yet-persisted drafts. The repository
  /// generates the id at create time.
  final String id;

  /// User-visible label shown in the picker (e.g. "Promo week-end").
  /// Distinct from `text` — the merchant scans the list by name, not body.
  final String name;

  /// Notification body text — the same string consumed by
  /// [SendMerchantNotification.text].
  final String text;

  /// "Tous mes clients" or "Certains clients". Same vocabulary as the
  /// existing send flow so loading a template is a 1:1 form fill.
  final String audience;

  /// Empty when audience = "Tous mes clients". For "Certains clients",
  /// the persisted segment selection — locked at template-save time so
  /// reloading later restores the same target group.
  final List<String> segments;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  NotificationTemplate copyWith({
    String? id,
    String? name,
    String? text,
    String? audience,
    List<String>? segments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      text: text ?? this.text,
      audience: audience ?? this.audience,
      segments: segments ?? this.segments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        text,
        audience,
        segments,
        createdAt,
        updatedAt,
      ];
}
