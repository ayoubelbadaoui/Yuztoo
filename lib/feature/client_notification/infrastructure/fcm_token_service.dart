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
/// Stores the token at `users/{uid}/push_tokens/device` so Cloud Functions
/// can send targeted push notifications when notifications are created.
class FcmTokenService {
  FcmTokenService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Stopped in [clearToken] so token rotation cannot write after sign-out.
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Watches `push_tokens/device`. If Cloud Function deletes it (invalid token),
  /// we immediately re-fetch and re-persist so the next notification is delivered.
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _tokenDocSubscription;

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

      // NOTE: setForegroundNotificationPresentationOptions is intentionally
      // NOT called here — main_shell_state._requestRuntimePermissions() already
      // sets alert:false (suppress system banner, use Flutter overlay instead).
      // Calling it here a second time causes a harmless race but is unnecessary.

      // Ask Android to exempt this app from battery optimisation.
      // Without this Samsung/Xiaomi/etc. kill FCM delivery after ~20 min idle.
      await _requestBatteryExemption();

      // On iOS, FCM can return a token before APNs has issued a device token.
      // The resulting FCM token has no APNs binding and Firebase silently
      // drops sends to it — the symptom is "permission granted, no pushes".
      // Wait (with timeout) for getAPNSToken to come back non-null first.
      if (Platform.isIOS) {
        final apnsToken = await _waitForApnsToken(messaging);
        if (apnsToken == null) {
          LoggerService.logInfo(
            'APNs token unavailable — skipping FCM registration',
            context: {'userId': userId},
          );
          return;
        }
      }

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

  /// Poll FirebaseMessaging.getAPNSToken until it returns non-null or we hit
  /// the timeout. APNs typically issues the device token within ~1s of
  /// registerForRemoteNotifications, but on cold launch with poor network it
  /// can take several seconds — returning null means we should bail and let
  /// the next app-resume retry (didChangeAppLifecycleState calls us again).
  Future<String?> _waitForApnsToken(
    FirebaseMessaging messaging, {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final token = await messaging.getAPNSToken();
      if (token != null && token.isNotEmpty) return token;
      await Future<void>.delayed(interval);
    }
    return null;
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
    final tokenRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('push_tokens')
        .doc('device');

    await tokenRef.set(
      {
        'fcm_token': token,
        'updated_at': FieldValue.serverTimestamp(),
        'platform': _platform(),
      },
      SetOptions(merge: true),
    );
    LoggerService.logInfo('FCM token saved', context: {'userId': userId});

    // Watch the token document. If Cloud Function deletes it (because the token
    // was invalidated/unregistered), immediately re-fetch and re-persist so the
    // user continues receiving notifications without needing to restart the app.
    _tokenDocSubscription?.cancel();
    _tokenDocSubscription = tokenRef.snapshots().listen(
      (snap) async {
        if (!snap.exists) {
          // Document was deleted externally (e.g., Cloud Function on invalid token).
          final currentUid =
              firebase_auth.FirebaseAuth.instance.currentUser?.uid;
          if (currentUid == null || currentUid != userId) return;
          try {
            final newToken = await FirebaseMessaging.instance.getToken();
            if (newToken != null && newToken.isNotEmpty) {
              await _persistToken(userId, newToken);
              LoggerService.logInfo(
                'FCM token auto-recovered after deletion',
                context: {'userId': userId},
              );
            }
          } catch (e, st) {
            LoggerService.logError(
              'FCM token auto-recovery failed',
              error: e,
              stackTrace: st,
              context: {'userId': userId},
            );
          }
        }
      },
      onError: (_) {}, // Ignore Firestore permission errors on sign-out.
    );
  }

  static String _platform() => Platform.isAndroid ? 'android' : 'ios';

  /// Remove the FCM token on sign-out so push notifications stop.
  Future<void> clearToken(String userId) async {
    if (userId.isEmpty) return;
    // Cancel subscriptions BEFORE deleting the document to prevent the
    // Firestore watch from trying to auto-recover a legitimately cleared token.
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _tokenDocSubscription?.cancel();
    _tokenDocSubscription = null;
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
