import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles in-app notification banners (foreground FCM messages).
///
/// - Initialises the [FlutterLocalNotificationsPlugin] and the Android channel.
/// - [showFromRemoteMessage] must be called inside [FirebaseMessaging.onMessage]
///   to display a banner while the app is in the foreground.
/// - On tap the notification dismisses automatically; the caller can listen
///   to [onNotificationTap] to react (e.g. open the notifications screen).
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _channelId = 'yuztoo_promotions';
  static const _channelName = 'Promotions & actualités';
  static const _channelDesc = 'Notifications des promotions et offres des commerces suivis.';

  final _plugin = FlutterLocalNotificationsPlugin();

  // Stream of notification-tap payloads so the UI can react.
  final _tapController = _StreamController<String?>();
  Stream<String?> get onNotificationTap => _tapController.stream;

  bool _initialized = false;

  /// Call once at app startup (before [FirebaseMessaging.onMessage] is set).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        _tapController.add(details.payload);
      },
    );

    // Create Android high-importance channel so banners appear like IG/FB.
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Show a local banner from an FCM [RemoteMessage] (foreground only).
  Future<void> showFromRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? 'Yuztoo';
    final body = notification.body ?? '';
    final payload = message.data['notification_id'];

    final int id = message.hashCode.abs() % 100000;

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          ticker: title,
          playSound: true,
          enableVibration: true,
          // Use the app launcher icon; replace with a dedicated white icon later.
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  void dispose() => _tapController.close();
}

// Minimal single-subscription stream controller helper.
class _StreamController<T> {
  final _listeners = <void Function(T)>[];

  Stream<T> get stream => Stream.multi((controller) {
        final fn = (T value) => controller.add(value);
        _listeners.add(fn);
        controller.onCancel = () => _listeners.remove(fn);
      });

  void add(T value) {
    for (final l in _listeners) {
      l(value);
    }
  }

  void close() => _listeners.clear();
}
