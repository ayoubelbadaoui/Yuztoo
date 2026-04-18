import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/infrastructure/logger_service.dart';

/// Manages FCM token registration for the current device.
///
/// Stores the token at `users/{uid}/fcm_token` so Cloud Functions can
/// send targeted push notifications when notifications are created.
class FcmTokenService {
  FcmTokenService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Request permission and persist the FCM token for [userId].
  ///
  /// Safe to call multiple times — uses `SetOptions(merge: true)`.
  Future<void> registerToken(String userId) async {
    if (userId.isEmpty) return;
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      await _persistToken(userId, token);

      // Keep token fresh when it rotates (e.g. app reinstall, token expiry).
      messaging.onTokenRefresh.listen(
        (newToken) => _persistToken(userId, newToken),
      );
    } catch (e, st) {
      LoggerService.logError(
        'FCM token registration failed',
        error: e,
        stackTrace: st,
        context: {'userId': userId},
      );
    }
  }

  Future<void> _persistToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).set(
      {
        'fcm_token': token,
        'fcm_token_updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    LoggerService.logInfo('FCM token saved', context: {'userId': userId});
  }

  /// Remove the FCM token on sign-out so push notifications stop.
  Future<void> clearToken(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _firestore.collection('users').doc(userId).set(
        {'fcm_token': null},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }
}

final fcmTokenServiceProvider = Provider<FcmTokenService>((ref) {
  return FcmTokenService(firestore: FirebaseFirestore.instance);
});
