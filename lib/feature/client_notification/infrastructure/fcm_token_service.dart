import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
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

  /// Stopped in [clearToken] so token rotation cannot write after sign-out.
  StreamSubscription<String>? _tokenRefreshSubscription;

  static const _batteryChannel =
      MethodChannel('com.yuztoo.app/battery');

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

      // iOS: play sound + update badge in foreground, but suppress the system
      // banner — the Flutter overlay in main_shell_state handles the visual.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );

      // Ask Android to exempt this app from battery optimisation.
      // Without this Samsung/Xiaomi/etc. kill FCM delivery after ~20 min idle.
      await _requestBatteryExemption();

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      await _persistToken(userId, token);

      // Keep token fresh when it rotates (e.g. app reinstall, token expiry).
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
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

  /// Opens the system dialog asking the user to exempt this app from
  /// battery optimisation — the single most common cause of missed FCM
  /// pushes on Samsung / Xiaomi / OPPO / OnePlus devices.
  Future<void> _requestBatteryExemption() async {
    try {
      final isExempt = await _batteryChannel
          .invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
          false;
      if (!isExempt) {
        await _batteryChannel
            .invokeMethod('requestIgnoreBatteryOptimizations');
      }
    } on MissingPluginException {
      // Not on Android — no-op.
    } catch (_) {
      // Non-critical — don't block token registration.
    }
  }

  Future<void> _persistToken(String userId, String token) async {
    // After sign-out, [FirebaseAuth] has no user — Firestore rules deny writes to
    // `users/{userId}/push_tokens/*`. Token refresh can still fire asynchronously.
    final authUid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (authUid == null || authUid != userId) {
      return;
    }

    // Store in a subcollection so we don't trigger the strict shape-validation
    // rules on the root /users/{uid} document.
    // Path: users/{uid}/push_tokens/device
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('push_tokens')
        .doc('device')
        .set(
      {
        'fcm_token': token,
        'updated_at': FieldValue.serverTimestamp(),
        'platform': _platform(),
      },
      SetOptions(merge: true),
    );
    LoggerService.logInfo('FCM token saved', context: {'userId': userId});
  }

  static String _platform() => Platform.isAndroid ? 'android' : 'ios';

  /// Remove the FCM token on sign-out so push notifications stop.
  Future<void> clearToken(String userId) async {
    if (userId.isEmpty) return;
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('push_tokens')
          .doc('device')
          .delete();
    } catch (_) {}
  }
}

final fcmTokenServiceProvider = Provider<FcmTokenService>((ref) {
  return FcmTokenService(firestore: FirebaseFirestore.instance);
});
