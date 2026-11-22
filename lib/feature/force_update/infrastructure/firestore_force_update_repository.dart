import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/infrastructure/logger_service.dart';
import '../domain/entities/force_update_config.dart';
import '../domain/repositories/i_force_update_repository.dart';

/// Firestore layout — Admin SDK / CRM callables only:
///
/// ```
/// app_config/force_update
///   force               bool
///   android_min_build   int
///   ios_min_build       int
///   message_fr          string?
///   android_store_url   string?
///   ios_store_url       string?
///   updated_at          timestamp?
///   updated_by          string?
/// ```
class FirestoreForceUpdateRepository implements IForceUpdateRepository {
  FirestoreForceUpdateRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const String collection = 'app_config';
  static const String docId = 'force_update';

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection(collection).doc(docId);

  @override
  Stream<ForceUpdateConfig> watchConfig() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return ForceUpdateConfig.disabled;
      }
      return configFromMap(snap.data()!);
    }).handleError((Object e, StackTrace st) {
      LoggerService.logError(
        'Failed to watch force_update config',
        error: e,
        stackTrace: st,
      );
    });
  }

  /// Shared with unit tests — maps a Firestore map to [ForceUpdateConfig].
  static ForceUpdateConfig configFromMap(Map<String, dynamic> data) {
    return ForceUpdateConfig(
      force: data['force'] == true,
      androidMinBuild: _asNonNegInt(data['android_min_build']),
      iosMinBuild: _asNonNegInt(data['ios_min_build']),
      messageFr: _nonEmpty(data['message_fr']),
      androidStoreUrl: _nonEmpty(data['android_store_url']),
      iosStoreUrl: _nonEmpty(data['ios_store_url']),
    );
  }

  static int _asNonNegInt(dynamic raw) {
    if (raw is int) return raw < 0 ? 0 : raw;
    if (raw is num) {
      final v = raw.toInt();
      return v < 0 ? 0 : v;
    }
    if (raw is String) {
      final v = int.tryParse(raw.trim());
      if (v == null || v < 0) return 0;
      return v;
    }
    return 0;
  }

  static String? _nonEmpty(dynamic raw) {
    final value = raw is String ? raw.trim() : '';
    return value.isEmpty ? null : value;
  }
}
