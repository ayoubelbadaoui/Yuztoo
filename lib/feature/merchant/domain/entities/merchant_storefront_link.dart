import 'package:equatable/equatable.dart';

/// Merchant-defined vitrine entry (reservation link, menu, Instagram, etc.).
class MerchantStorefrontLink extends Equatable {
  const MerchantStorefrontLink({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  bool get isValid => label.trim().isNotEmpty && value.trim().isNotEmpty;

  /// True when [value] can be opened in the browser / external app.
  bool get isLaunchableUrl => looksLikeUrl(value);

  Uri? get launchUri {
    if (!isLaunchableUrl) return null;
    final trimmed = value.trim();
    return Uri.tryParse(
      trimmed.contains('://') ? trimmed : 'https://$trimmed',
    );
  }

  static bool looksLikeUrl(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return false;
    final lower = t.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      final uri = Uri.tryParse(t);
      return uri != null && uri.hasScheme;
    }
    if (RegExp(r'^\w+:').hasMatch(t)) return false;
    final uri = Uri.tryParse('https://$t');
    if (uri == null || !uri.hasScheme) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  factory MerchantStorefrontLink.fromMap(Map<String, dynamic> map) {
    return MerchantStorefrontLink(
      label: (map['label'] as String? ?? '').trim(),
      value: (map['value'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label.trim(),
        'value': value.trim(),
      };

  MerchantStorefrontLink copyWith({String? label, String? value}) {
    return MerchantStorefrontLink(
      label: label ?? this.label,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [label, value];
}
