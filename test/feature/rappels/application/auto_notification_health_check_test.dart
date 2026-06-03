import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/rappels/application/auto_notification_health_check.dart';

void main() {
  const userId = 'u1';
  const merchantId = 'm1';

  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  AutoNotificationHealthChecker buildChecker(
    PushPermissionStatus permission,
  ) {
    return AutoNotificationHealthChecker(
      firestore: firestore,
      pushPermissionResolver: () async => permission,
    );
  }

  Future<void> seedToken({String token = 'fcm-abc'}) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('push_tokens')
        .doc('device')
        .set({'fcm_token': token});
  }

  Future<void> seedMerchant({Object? autoEnabledOverride = _absent}) async {
    final data = <String, dynamic>{'name': 'Test'};
    if (autoEnabledOverride != _absent) {
      data['notifications_auto_enabled'] = autoEnabledOverride;
    }
    await firestore.collection('merchants').doc(merchantId).set(data);
  }

  Future<void> seedNotif({
    required String id,
    required bool enabled,
    DateTime? lastSentAt,
  }) async {
    await firestore
        .collection('merchants')
        .doc(merchantId)
        .collection('auto_notifications')
        .doc(id)
        .set({
      'is_enabled': enabled,
      'text': 'x',
      'trigger': 'Date anniversaire client',
      'audience': 'Tous mes clients',
      'target_segments': <String>[],
      if (lastSentAt != null) 'last_sent_at': Timestamp.fromDate(lastSentAt),
    });
  }

  group('AutoNotificationHealthReport', () {
    test('isFullyOperational requires every gate', () {
      const report = AutoNotificationHealthReport(
        pushPermission: PushPermissionStatus.granted,
        fcmTokenRegistered: true,
        merchantAutoEnabled: true,
        totalTemplates: 1,
        enabledTemplates: 1,
      );
      expect(report.isFullyOperational, isTrue);
    });

    test('not operational when push permission is denied', () {
      const report = AutoNotificationHealthReport(
        pushPermission: PushPermissionStatus.denied,
        fcmTokenRegistered: true,
        merchantAutoEnabled: true,
        totalTemplates: 1,
        enabledTemplates: 1,
      );
      expect(report.isFullyOperational, isFalse);
      expect(report.pushAllowed, isFalse);
    });

    test('provisional permission counts as allowed', () {
      const report = AutoNotificationHealthReport(
        pushPermission: PushPermissionStatus.provisional,
        fcmTokenRegistered: true,
        merchantAutoEnabled: true,
        totalTemplates: 1,
        enabledTemplates: 1,
      );
      expect(report.pushAllowed, isTrue);
      expect(report.isFullyOperational, isTrue);
    });

    test('not operational when no template is enabled', () {
      const report = AutoNotificationHealthReport(
        pushPermission: PushPermissionStatus.granted,
        fcmTokenRegistered: true,
        merchantAutoEnabled: true,
        totalTemplates: 3,
        enabledTemplates: 0,
      );
      expect(report.isFullyOperational, isFalse);
    });
  });

  group('AutoNotificationHealthChecker.check', () {
    test('all green path', () async {
      await seedToken();
      await seedMerchant();
      await seedNotif(id: 'n1', enabled: true);

      final report = await buildChecker(PushPermissionStatus.granted)
          .check(userId: userId, merchantId: merchantId);

      expect(report.pushPermission, PushPermissionStatus.granted);
      expect(report.fcmTokenRegistered, isTrue);
      expect(report.merchantAutoEnabled, isTrue);
      expect(report.totalTemplates, 1);
      expect(report.enabledTemplates, 1);
      expect(report.isFullyOperational, isTrue);
    });

    test('missing FCM token surfaces clearly', () async {
      await seedMerchant();
      await seedNotif(id: 'n1', enabled: true);

      final report = await buildChecker(PushPermissionStatus.granted)
          .check(userId: userId, merchantId: merchantId);

      expect(report.fcmTokenRegistered, isFalse);
      expect(report.isFullyOperational, isFalse);
    });

    test('empty FCM token field treated as missing', () async {
      await seedToken(token: '');
      await seedMerchant();
      await seedNotif(id: 'n1', enabled: true);

      final report = await buildChecker(PushPermissionStatus.granted)
          .check(userId: userId, merchantId: merchantId);

      expect(report.fcmTokenRegistered, isFalse);
    });

    test('merchant flag absent → enabled (default policy)', () async {
      await seedToken();
      await seedMerchant();
      await seedNotif(id: 'n1', enabled: true);

      final report = await buildChecker(PushPermissionStatus.granted)
          .check(userId: userId, merchantId: merchantId);

      expect(report.merchantAutoEnabled, isTrue);
    });

    test('merchant flag set to false disables', () async {
      await seedToken();
      await seedMerchant(autoEnabledOverride: false);
      await seedNotif(id: 'n1', enabled: true);

      final report = await buildChecker(PushPermissionStatus.granted)
          .check(userId: userId, merchantId: merchantId);

      expect(report.merchantAutoEnabled, isFalse);
      expect(report.isFullyOperational, isFalse);
    });

    test('counts total vs enabled templates', () async {
      await seedToken();
      await seedMerchant();
      await seedNotif(id: 'n1', enabled: true);
      await seedNotif(id: 'n2', enabled: false);
      await seedNotif(id: 'n3', enabled: true);

      final report = await buildChecker(PushPermissionStatus.granted)
          .check(userId: userId, merchantId: merchantId);

      expect(report.totalTemplates, 3);
      expect(report.enabledTemplates, 2);
    });

    test('lastAutoSentAt picks the most recent timestamp', () async {
      await seedToken();
      await seedMerchant();
      final older = DateTime.utc(2026, 5, 1);
      final newer = DateTime.utc(2026, 5, 20);
      await seedNotif(id: 'n1', enabled: true, lastSentAt: older);
      await seedNotif(id: 'n2', enabled: true, lastSentAt: newer);
      await seedNotif(id: 'n3', enabled: true);

      final report = await buildChecker(PushPermissionStatus.granted)
          .check(userId: userId, merchantId: merchantId);

      // Compare instants — `Timestamp.toDate` returns a local-time wrapper
      // around the same UTC instant.
      expect(
        report.lastAutoSentAt!.isAtSameMomentAs(newer),
        isTrue,
        reason: 'expected $newer, got ${report.lastAutoSentAt}',
      );
    });

    test('lastAutoSentAt null when no template ever fired', () async {
      await seedToken();
      await seedMerchant();
      await seedNotif(id: 'n1', enabled: true);

      final report = await buildChecker(PushPermissionStatus.granted)
          .check(userId: userId, merchantId: merchantId);

      expect(report.lastAutoSentAt, isNull);
    });

    test('empty merchantId returns safe defaults', () async {
      final report = await buildChecker(PushPermissionStatus.granted)
          .check(userId: userId, merchantId: '');

      expect(report.merchantAutoEnabled, isFalse);
      expect(report.totalTemplates, 0);
      expect(report.enabledTemplates, 0);
      expect(report.isFullyOperational, isFalse);
    });

    test('empty userId means no token check', () async {
      await seedMerchant();
      await seedNotif(id: 'n1', enabled: true);

      final report = await buildChecker(PushPermissionStatus.granted)
          .check(userId: '', merchantId: merchantId);

      expect(report.fcmTokenRegistered, isFalse);
    });
  });
}

const Object _absent = Object();
