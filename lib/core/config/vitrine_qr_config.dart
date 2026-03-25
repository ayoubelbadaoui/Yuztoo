/// Canonical URLs encoded in merchant vitrine QR codes.
/// Each commerce has a unique [merchantId] segment.
///
/// Scanners (in-app or system camera + App Links later) resolve to the client vitrine.
abstract final class VitrineQrConfig {
  static const String _appHost = 'yuztoo.app';
  static const String _pathSegment = 'vitrine';

  /// HTTPS link shown in QR — unique per commerce; opens vitrine when handled by the app or site.
  static String uriStringForMerchant(String merchantId) {
    final id = merchantId.trim();
    if (id.isEmpty) return '';
    return 'https://$_appHost/$_pathSegment/$id';
  }

  /// Parses a scanned payload and returns the merchant document id, or null if not a vitrine QR.
  static String? tryParseMerchantId(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;

    final uri = Uri.tryParse(t);
    if (uri == null) return null;

    // yuztoo://vitrine/{merchantId}
    if (uri.scheme == 'yuztoo' && uri.host == _pathSegment) {
      final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segs.isNotEmpty) return segs.first;
    }

    // https://yuztoo.app/vitrine/{merchantId} (or www)
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      final host = uri.host.toLowerCase();
      if (host == _appHost || host == 'www.$_appHost') {
        final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segs.length >= 2 && segs[0] == _pathSegment) {
          return segs[1];
        }
      }
    }

    return null;
  }
}
