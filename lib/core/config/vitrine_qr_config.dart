/// Canonical URLs encoded in merchant vitrine QR codes.
/// Each commerce has a unique [merchantId] segment.
///
/// Scanners (in-app or system camera + App Links later) resolve to the client vitrine.
abstract final class VitrineQrConfig {
  static const String _appHost = 'yuztoo.web.app';
  static const String _pathSegment = 'vitrine';

  /// Hosts we accept when parsing an inbound vitrine link. Kept permissive so a
  /// tag/QR programmed for any of our domains still resolves in-app, regardless
  /// of which host we ultimately standardize on for store approval.
  static const Set<String> _acceptedHosts = {
    'yuztoo.app',
    'www.yuztoo.app',
    'yuztoo.web.app',
    'yuztoo.firebaseapp.com',
  };

  /// HTTPS link shown in QR — unique per commerce; opens vitrine when handled by the app or site.
  static String uriStringForMerchant(String merchantId) {
    final id = merchantId.trim();
    if (id.isEmpty) return '';
    return 'https://$_appHost/$_pathSegment/$id';
  }

  /// Merchant ids are Firebase uids / auto ids. Anything else (encoded `/`,
  /// `..`, `__x__`, oversized) is an invalid Firestore document id and
  /// would throw when used in a path.
  static final RegExp _merchantIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  /// Parses a scanned payload and returns the merchant document id, or null if not a vitrine QR.
  static String? tryParseMerchantId(String raw) {
    final String? id;
    try {
      id = _tryParseRawMerchantId(raw);
    } on FormatException {
      // Malformed percent-encoding in a crafted QR / tag payload.
      return null;
    }
    return id != null && isValidMerchantId(id) ? id : null;
  }

  /// Parses a Play Store install-referrer payload written by `public/vitrine.html`.
  ///
  /// Accepted shapes:
  /// - `vitrine=<merchantId>`
  /// - `utm_content=<merchantId>`
  /// - a full `https://…/vitrine/<id>` or `yuztoo://vitrine/<id>` URL
  static String? tryParseMerchantIdFromInstallReferrer(String? referrer) {
    if (referrer == null) return null;
    final raw = referrer.trim();
    if (raw.isEmpty) return null;

    final asLink = tryParseMerchantId(raw);
    if (asLink != null) return asLink;

    // Referrers are often still percent-encoded once.
    String decoded = raw;
    try {
      decoded = Uri.decodeComponent(raw);
    } catch (_) {}
    if (decoded != raw) {
      final decodedLink = tryParseMerchantId(decoded);
      if (decodedLink != null) return decodedLink;
    }

    final params = Uri.splitQueryString(decoded);
    for (final key in const ['vitrine', 'utm_content', 'id']) {
      final value = params[key]?.trim();
      if (value != null && isValidMerchantId(value)) return value;
    }
    return null;
  }

  static bool isValidMerchantId(String id) =>
      _merchantIdPattern.hasMatch(id) &&
      !(id.startsWith('__') && id.endsWith('__'));

  static String? _tryParseRawMerchantId(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;

    final uri = Uri.tryParse(t);
    if (uri == null) return null;

    // yuztoo://vitrine/{merchantId}
    if (uri.scheme == 'yuztoo' && uri.host == _pathSegment) {
      final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segs.isNotEmpty) return segs.first;
    }

    // https://<accepted-host>/vitrine/{merchantId}
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      final host = uri.host.toLowerCase();
      if (_acceptedHosts.contains(host)) {
        final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segs.length >= 2 && segs[0] == _pathSegment) {
          return segs[1];
        }
      }
    }

    return null;
  }
}
