import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Builds a structured JSON export of the signed-in user's own Firestore data
/// (RGPD / GDPR Art. 20 — right to data portability). Only reads paths allowed
/// by security rules for the owning user.
class PortableUserDataExport {
  PortableUserDataExport(this._firestore);

  final FirebaseFirestore _firestore;

  static const int _kNotificationsCap = 500;

  /// ISO-8601 snapshot time in UTC (client clock).
  Future<Map<String, dynamic>> buildExport({
    required String uid,
    String? authEmail,
  }) async {
    final exportedAt = DateTime.now().toUtc().toIso8601String();

    final userRef = _firestore.collection('users').doc(uid);
    final userSnap = await userRef.get();
    final userData = userSnap.data();

    final followedSnap =
        await userRef.collection('followed_merchants').get();
    final followed = <String, dynamic>{};
    for (final d in followedSnap.docs) {
      followed[d.id] = _jsonify(d.data());
    }

    final loyaltyByMerchant = <String, dynamic>{};
    for (final d in followedSnap.docs) {
      final mid = d.id;
      try {
        final lc = await _firestore
            .collection('merchants')
            .doc(mid)
            .collection('loyalty_clients')
            .doc(uid)
            .get();
        if (lc.exists) {
          loyaltyByMerchant[mid] = _jsonify(lc.data());
        }
      } catch (e, st) {
        debugPrint('[PortableUserDataExport] loyalty_clients $mid: $e\n$st');
      }
    }

    final bonsSnap = await userRef.collection('loyalty_bons').get();
    final loyaltyBons = <Map<String, dynamic>>[];
    for (final d in bonsSnap.docs) {
      loyaltyBons.add(<String, dynamic>{
        'id': d.id,
        'data': _jsonify(d.data()),
      });
    }

    final blockedSnap = await userRef.collection('blocked_merchants').get();
    final blocked = <String, dynamic>{};
    for (final d in blockedSnap.docs) {
      blocked[d.id] = _jsonify(d.data());
    }

    final notifSnap =
        await userRef.collection('notifications').limit(_kNotificationsCap).get();
    final notifications = <Map<String, dynamic>>[];
    for (final d in notifSnap.docs) {
      notifications.add(<String, dynamic>{
        'id': d.id,
        'data': _jsonify(d.data()),
      });
    }

    Map<String, dynamic>? merchantProfile;
    final merchantId = userData?['merchant_id'] as String?;
    if (merchantId != null && merchantId.isNotEmpty) {
      try {
        final m =
            await _firestore.collection('merchants').doc(merchantId).get();
        if (m.exists) {
          merchantProfile = _jsonify(m.data()) as Map<String, dynamic>?;
        }
      } catch (e, st) {
        debugPrint('[PortableUserDataExport] merchant $merchantId: $e\n$st');
      }
    }

    return <String, dynamic>{
      'export_schema_version': 1,
      'exported_at_utc': exportedAt,
      'uid': uid,
      'auth_email_at_export': authEmail,
      'notice':
          'Export généré depuis l’application. Les jetons push (FCM) ne sont '
          'pas inclus. Les notifications sont limitées aux $_kNotificationsCap '
          'plus récentes récupérées par l’application.',
      'user_profile': userData != null ? _jsonify(userData) : null,
      'followed_merchants': followed,
      'loyalty_progress_by_merchant_id': loyaltyByMerchant,
      'loyalty_bons': loyaltyBons,
      'blocked_merchants': blocked,
      'notifications': notifications,
      if (merchantProfile != null) 'merchant_business_profile': merchantProfile,
    };
  }

  static dynamic _jsonify(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is GeoPoint) {
      return <String, double>{
        'latitude': value.latitude,
        'longitude': value.longitude,
      };
    }
    if (value is Map) {
      return value.map(
        (k, v) => MapEntry(k.toString(), _jsonify(v)),
      );
    }
    if (value is Iterable) {
      return value.map(_jsonify).toList();
    }
    if (value is num || value is bool || value is String) {
      return value;
    }
    return value.toString();
  }
}
