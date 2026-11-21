import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_media_release.dart';
import '../domain/app_media_slot.dart';
import '../domain/repositories/app_media_repository.dart';

class FirestoreAppMediaRepository implements AppMediaRepository {
  FirestoreAppMediaRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _releasePath = 'app_config/app_media_release';
  static const _catalogPath = 'app_config/app_media_catalog';

  @override
  Future<AppMediaRelease> fetchRelease() async {
    try {
      final snap = await _firestore.doc(_releasePath).get();
      if (!snap.exists || snap.data() == null) {
        return AppMediaRelease.draft;
      }
      return _mapRelease(snap.data()!);
    } on FirebaseException catch (e) {
      // Missing permission / offline → treat as draft (use bundled assets).
      if (e.code == 'permission-denied' || e.code == 'unavailable') {
        return AppMediaRelease.draft;
      }
      rethrow;
    }
  }

  @override
  Future<Map<AppMediaSlotId, String>> fetchCatalogUrls() async {
    try {
      final snap = await _firestore.doc(_catalogPath).get();
      if (!snap.exists || snap.data() == null) return {};
      final rawSlots = snap.data()!['slots'];
      if (rawSlots is! Map) return {};

      final out = <AppMediaSlotId, String>{};
      for (final entry in rawSlots.entries) {
        final id = AppMediaSlotId.tryParse(entry.key.toString());
        if (id == null) continue;
        final value = entry.value;
        if (value is! Map) continue;
        final url = value['url'];
        if (url is String && url.startsWith('https://')) {
          out[id] = url;
        }
      }
      return out;
    } on FirebaseException catch (e) {
      // Draft / non-test preview user → rules deny catalog (intentional).
      if (e.code == 'permission-denied' || e.code == 'not-found') {
        return {};
      }
      rethrow;
    }
  }

  AppMediaRelease _mapRelease(Map<String, dynamic> data) {
    final statusRaw = data['status']?.toString() ?? 'draft';
    final status = switch (statusRaw) {
      'preview' => AppMediaReleaseStatus.preview,
      'live' => AppMediaReleaseStatus.live,
      _ => AppMediaReleaseStatus.draft,
    };
    return AppMediaRelease(
      status: status,
      testAccountId: data['testAccountId'] as String?,
      testAccountKind: data['testAccountKind'] as String?,
      testAccountLabel: data['testAccountLabel'] as String?,
      previewActivatedAt: _asDate(data['previewActivatedAt']),
      liveAt: _asDate(data['liveAt']),
    );
  }

  DateTime? _asDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
