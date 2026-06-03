/// Health-check for the auto-notification pipeline as it would behave on
/// the user's CURRENT device + merchant account.
///
/// Why this exists: the auto-notif system has many moving parts —
/// FCM permission, FCM token persistence, merchant-level enable flag,
/// active templates, daily cron at 09:00 Paris. When a merchant says
/// "ça ne marche pas", it can be any of those, and from the app there's
/// no way to know which. This module exposes a single async check that
/// surfaces every gate one by one so the UI can show the user exactly
/// what's missing.
///
/// Pure data class + an injected runner make this testable without
/// pulling Firebase into unit tests.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Authorisation status reported by the OS for notifications.
enum PushPermissionStatus {
  /// The user explicitly granted permission. Pushes will be displayed.
  granted,

  /// The user explicitly denied permission. Pushes will never be displayed,
  /// even if FCM successfully delivers them.
  denied,

  /// iOS provisional auth — pushes are delivered silently to the
  /// notification center; the OS does not interrupt the user.
  provisional,

  /// The user has not been asked yet (cold install) — re-prompt is needed.
  notDetermined,

  /// FCM SDK could not determine the state (rare; typically Android <13).
  unknown,
}

/// Aggregated state of every gate that must be green for the merchant to
/// actually receive auto-notifications on this device.
class AutoNotificationHealthReport {
  const AutoNotificationHealthReport({
    required this.pushPermission,
    required this.fcmTokenRegistered,
    required this.merchantAutoEnabled,
    required this.totalTemplates,
    required this.enabledTemplates,
    this.lastAutoSentAt,
  });

  /// Result of `FirebaseMessaging.getNotificationSettings`. When this is
  /// anything other than [PushPermissionStatus.granted] (or [provisional]
  /// on iOS), the OS will silently swallow every push the backend sends.
  final PushPermissionStatus pushPermission;

  /// True when `users/{uid}/push_tokens/device` exists with a non-empty
  /// `fcm_token` field. Set by [FcmTokenService] on every cold-start.
  /// If this is false, the backend has nowhere to push to.
  final bool fcmTokenRegistered;

  /// Reflects `merchants/{merchantId}.notifications_auto_enabled`. When
  /// `false`, the daily cron and every event-based dispatcher skip this
  /// merchant entirely — the master kill-switch.
  final bool merchantAutoEnabled;

  /// Total number of templates the merchant has created (any state).
  final int totalTemplates;

  /// Subset of [totalTemplates] with `is_enabled == true`. The cron and
  /// dispatchers only consider enabled templates — when this is 0 the
  /// merchant has nothing to fire.
  final int enabledTemplates;

  /// Most recent `last_sent_at` across all of the merchant's templates,
  /// or null if no template has ever fired. Useful as a proof-of-life:
  /// a non-null value means at least one auto-notif has reached at least
  /// one client at some point.
  final DateTime? lastAutoSentAt;

  /// True when every gate is green: push allowed, token registered,
  /// merchant enabled, and at least one template active.
  bool get isFullyOperational =>
      pushAllowed && fcmTokenRegistered && merchantAutoEnabled && enabledTemplates > 0;

  /// True when the OS will display incoming pushes. Provisional counts
  /// because the notification still reaches the device (notification
  /// center) — the OS just doesn't interrupt the user.
  bool get pushAllowed =>
      pushPermission == PushPermissionStatus.granted ||
      pushPermission == PushPermissionStatus.provisional;
}

/// Adapter around [FirebaseMessaging] so unit tests can substitute a fake.
typedef PushPermissionResolver = Future<PushPermissionStatus> Function();

/// Default resolver that asks [FirebaseMessaging] for the current OS state.
/// Translation is wrapped in try/catch — on rare devices the SDK throws
/// instead of returning notDetermined, and we want a graceful fallback
/// rather than an exploding diagnostic UI.
Future<PushPermissionStatus> defaultPushPermissionResolver() async {
  try {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        return PushPermissionStatus.granted;
      case AuthorizationStatus.denied:
        return PushPermissionStatus.denied;
      case AuthorizationStatus.provisional:
        return PushPermissionStatus.provisional;
      case AuthorizationStatus.notDetermined:
        return PushPermissionStatus.notDetermined;
    }
  } catch (_) {
    return PushPermissionStatus.unknown;
  }
}

/// Runs every check in parallel and returns the aggregated report.
///
/// All Firestore reads are bounded by `merchantId` and `userId` — the
/// reads are 1 doc + 1 collection scan (auto_notifications), so cost is
/// at most O(N templates) which is small in practice (<20).
class AutoNotificationHealthChecker {
  AutoNotificationHealthChecker({
    required FirebaseFirestore firestore,
    PushPermissionResolver? pushPermissionResolver,
  })  : _firestore = firestore,
        _pushPermissionResolver =
            pushPermissionResolver ?? defaultPushPermissionResolver;

  final FirebaseFirestore _firestore;
  final PushPermissionResolver _pushPermissionResolver;

  /// Gathers every gate. Errors on any individual sub-check are swallowed
  /// (returning the safest "missing" answer) so the diagnostic always
  /// produces a report — partial visibility beats a blank screen.
  Future<AutoNotificationHealthReport> check({
    required String userId,
    required String merchantId,
  }) async {
    final results = await Future.wait<dynamic>([
      _pushPermissionResolver(),
      _readFcmTokenRegistered(userId),
      _readMerchantAutoEnabled(merchantId),
      _readAutoNotifications(merchantId),
    ]);

    final permission = results[0] as PushPermissionStatus;
    final tokenRegistered = results[1] as bool;
    final merchantEnabled = results[2] as bool;
    final notifs = results[3] as _AutoNotifTallySummary;

    return AutoNotificationHealthReport(
      pushPermission: permission,
      fcmTokenRegistered: tokenRegistered,
      merchantAutoEnabled: merchantEnabled,
      totalTemplates: notifs.total,
      enabledTemplates: notifs.enabled,
      lastAutoSentAt: notifs.lastSentAt,
    );
  }

  Future<bool> _readFcmTokenRegistered(String userId) async {
    if (userId.isEmpty) return false;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('push_tokens')
          .doc('device')
          .get();
      if (!doc.exists) return false;
      final token = doc.data()?['fcm_token'];
      return token is String && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _readMerchantAutoEnabled(String merchantId) async {
    if (merchantId.isEmpty) return false;
    try {
      final doc = await _firestore.collection('merchants').doc(merchantId).get();
      if (!doc.exists) return false;
      // Match `isMerchantAutoNotificationsEnabled` (Cloud Functions): only
      // a strict `false` (or 0/"0") disables. Anything else, including
      // missing the field entirely, is treated as enabled.
      final v = doc.data()?['notifications_auto_enabled'];
      if (v == false) return false;
      if (v == 0 || v == '0') return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<_AutoNotifTallySummary> _readAutoNotifications(
      String merchantId) async {
    if (merchantId.isEmpty) return const _AutoNotifTallySummary(0, 0, null);
    try {
      final snap = await _firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('auto_notifications')
          .get();
      var total = 0;
      var enabled = 0;
      DateTime? lastSent;
      for (final d in snap.docs) {
        total += 1;
        final data = d.data();
        if (data['is_enabled'] == true) enabled += 1;
        final ts = data['last_sent_at'];
        if (ts is Timestamp) {
          final candidate = ts.toDate();
          if (lastSent == null || candidate.isAfter(lastSent)) {
            lastSent = candidate;
          }
        }
      }
      return _AutoNotifTallySummary(total, enabled, lastSent);
    } catch (_) {
      return const _AutoNotifTallySummary(0, 0, null);
    }
  }
}

class _AutoNotifTallySummary {
  const _AutoNotifTallySummary(this.total, this.enabled, this.lastSentAt);
  final int total;
  final int enabled;
  final DateTime? lastSentAt;
}
