/// God-level tests for the cloud-trigger status badge (claims 8 & 9).
///
/// Root bug: the auto-notification screen stored trigger rules in Firestore
/// but provided no indication to the merchant whether a trigger is handled
/// by a Cloud Function or not yet wired up. This caused confusion: rules
/// appeared saved but never fired for un-wired triggers.
///
/// Fix: `ActiveNotificationCard` now shows a cloud badge:
///  - "cloud_done" icon + "Exécuté automatiquement par le service cloud"
///    for triggers in AutoNotificationTriggers.wiredInCloud
///  - "cloud_off" icon + "Déclencheur en cours d'intégration"
///    for triggers NOT in wiredInCloud (e.g. visitDetected)

library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/auto_notification_triggers.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/entities/active_notification.dart';
import 'package:flutter_yuztoo/feature/rappels/presentation/widgets/active_notification_card.dart';

// ─── Helper ───────────────────────────────────────────────────────────────────

ActiveNotification _notif(String trigger, {bool enabled = true}) =>
    ActiveNotification(
      id: 'test-id',
      merchantId: 'merchant-1',
      text: 'Message de test',
      trigger: trigger,
      audience: 'Tous mes clients',
      isEnabled: enabled,
    );

Widget _wrap(ActiveNotification notification) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ActiveNotificationCard(
            notification: notification,
            onToggle: (_) {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── AutoNotificationTriggers.isWiredInCloud — pure logic ──────────────────

  group('AutoNotificationTriggers.isWiredInCloud', () {
    test('birthday is wired in cloud', () {
      expect(
        AutoNotificationTriggers.isWiredInCloud(
            AutoNotificationTriggers.birthday),
        isTrue,
      );
    });

    test('segmentChange is wired in cloud', () {
      expect(
        AutoNotificationTriggers.isWiredInCloud(
            AutoNotificationTriggers.segmentChange),
        isTrue,
      );
    });

    test('newFollower is wired in cloud', () {
      expect(
        AutoNotificationTriggers.isWiredInCloud(
            AutoNotificationTriggers.newFollower),
        isTrue,
      );
    });

    test('passageValidated is wired in cloud', () {
      expect(
        AutoNotificationTriggers.isWiredInCloud(
            AutoNotificationTriggers.passageValidated),
        isTrue,
      );
    });

    test('inactiveReturn is wired in cloud', () {
      expect(
        AutoNotificationTriggers.isWiredInCloud(
            AutoNotificationTriggers.inactiveReturn),
        isTrue,
      );
    });

    test('rewardAvailable is wired in cloud', () {
      expect(
        AutoNotificationTriggers.isWiredInCloud(
            AutoNotificationTriggers.rewardAvailable),
        isTrue,
      );
    });

    test('rewardNear is wired in cloud', () {
      expect(
        AutoNotificationTriggers.isWiredInCloud(
            AutoNotificationTriggers.rewardNear),
        isTrue,
      );
    });

    test('exceptionalClosure is wired in cloud', () {
      expect(
        AutoNotificationTriggers.isWiredInCloud(
            AutoNotificationTriggers.exceptionalClosure),
        isTrue,
      );
    });

    test('newPartner is wired in cloud', () {
      expect(
        AutoNotificationTriggers.isWiredInCloud(
            AutoNotificationTriggers.newPartner),
        isTrue,
      );
    });

    test('connectionAnniversary is wired in cloud', () {
      expect(
        AutoNotificationTriggers.isWiredInCloud(
            AutoNotificationTriggers.connectionAnniversary),
        isTrue,
      );
    });

    test('visitDetected is NOT wired in cloud', () {
      expect(
        AutoNotificationTriggers.isWiredInCloud(
            AutoNotificationTriggers.visitDetected),
        isFalse,
      );
    });

    test('unknown trigger string is NOT wired in cloud', () {
      expect(
        AutoNotificationTriggers.isWiredInCloud('some-future-trigger'),
        isFalse,
      );
    });

    test('all triggerLabels are either wired or have visitDetected as the sole un-wired entry', () {
      final unwired = AutoNotificationTriggers.triggerLabels
          .where((t) => !AutoNotificationTriggers.isWiredInCloud(t))
          .toList();
      // Only visitDetected is currently un-wired; this test fails fast
      // if a new trigger is added without being added to wiredInCloud.
      expect(unwired, [AutoNotificationTriggers.visitDetected]);
    });
  });

  // ── ActiveNotificationCard cloud badge — widget rendering ─────────────────

  group('ActiveNotificationCard cloud badge', () {
    testWidgets(
        'birthday trigger shows cloud_done icon',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_notif(AutoNotificationTriggers.birthday)),
      );
      await tester.pump();

      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    });

    testWidgets(
        'birthday trigger shows "Exécuté automatiquement" label',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_notif(AutoNotificationTriggers.birthday)),
      );
      await tester.pump();

      expect(
        find.textContaining('automatiquement'),
        findsOneWidget,
      );
    });

    testWidgets(
        'visitDetected trigger shows cloud_off icon',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_notif(AutoNotificationTriggers.visitDetected)),
      );
      await tester.pump();

      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets(
        'visitDetected trigger shows "intégration" label',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_notif(AutoNotificationTriggers.visitDetected)),
      );
      await tester.pump();

      expect(
        find.textContaining('intégration'),
        findsOneWidget,
      );
    });

    testWidgets(
        'passageValidated (wired) shows cloud_done, not cloud_off',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_notif(AutoNotificationTriggers.passageValidated)),
      );
      await tester.pump();

      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    });

    testWidgets(
        'unknown trigger shows cloud_off (safe default)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_notif('some-unknown-trigger')),
      );
      await tester.pump();

      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets(
        'badge shows for disabled cards as well as enabled',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_notif(AutoNotificationTriggers.birthday, enabled: false)),
      );
      await tester.pump();

      // Disabled card still shows the cloud badge.
      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    });

    testWidgets(
        'card also shows trigger pill and audience pill alongside cloud badge',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_notif(AutoNotificationTriggers.segmentChange)),
      );
      await tester.pump();

      // Trigger label pill.
      expect(
        find.text(AutoNotificationTriggers.segmentChange),
        findsOneWidget,
      );
      // Audience pill.
      expect(find.text('Tous mes clients'), findsOneWidget);
      // Cloud badge icon.
      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    });

    testWidgets(
        'exactly one cloud badge per card (no duplication)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_notif(AutoNotificationTriggers.inactiveReturn)),
      );
      await tester.pump();

      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    });
  });
}
