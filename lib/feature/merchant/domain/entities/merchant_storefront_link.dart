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

  /// What clients read on the vitrine: a short form of the URL (see
  /// [shortUrl]) or the free text unchanged.
  String get displayValue => isLaunchableUrl ? shortUrl(value) : value.trim();

  /// Longest `host/handle` kept by [shortUrl]; beyond that only the host.
  static const int shortUrlMaxLength = 28;

  /// `https://www.instagram.com/lebistro/?hl=fr` → `instagram.com/lebistro`
  /// (a single path segment is usually a profile handle), and
  /// `https://www.thefork.fr/restaurant/le-bistro-r123456` → `thefork.fr`.
  /// Returns [raw] trimmed when it cannot be parsed.
  static String shortUrl(String raw) {
    final t = raw.trim();
    final uri = Uri.tryParse(t.contains('://') ? t : 'https://$t');
    if (uri == null || uri.host.isEmpty) return t;
    var host = uri.host.toLowerCase();
    if (host.startsWith('www.')) host = host.substring(4);
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 1) return host;
    final withHandle = '$host/${segments.single}';
    return withHandle.length <= shortUrlMaxLength ? withHandle : host;
  }

  static bool looksLikeUrl(String raw) {
    final t = raw.trim();
    if (t.isEmpty || RegExp(r'\s').hasMatch(t)) return false;
    final lower = t.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      final uri = Uri.tryParse(t);
      return uri != null && uri.hasScheme && uri.host.isNotEmpty;
    }
    if (RegExp(r'^\w+:').hasMatch(t)) return false;
    final uri = Uri.tryParse('https://$t');
    if (uri == null || !uri.hasScheme) return false;
    final host = uri.host;
    return host.contains('.') && !host.startsWith('.') && !host.endsWith('.');
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
