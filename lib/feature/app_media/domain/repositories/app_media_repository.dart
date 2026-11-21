import '../app_media_release.dart';
import '../app_media_slot.dart';

/// Reads the 2-doc app media config. Writes stay on Admin callables only.
abstract class AppMediaRepository {
  Future<AppMediaRelease> fetchRelease();

  /// Slot id → HTTPS download URL. Empty when draft / not allowed / missing.
  Future<Map<AppMediaSlotId, String>> fetchCatalogUrls();
}
