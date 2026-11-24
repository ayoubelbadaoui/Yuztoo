import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/client_notification/application/notification_permission_prompt.dart';

void main() {
  final now = DateTime(2026, 11, 24, 12);

  bool offer({
    AuthorizationStatus status = AuthorizationStatus.notDetermined,
    bool isIOS = true,
    int offers = 0,
    DateTime? last,
  }) =>
      NotificationPermissionPrompt.shouldOffer(
        status: status,
        isIOS: isIOS,
        offersSoFar: offers,
        lastOffer: last,
        now: now,
      );

  group('when to show the notification explanation', () {
    test('never asked → offered', () => expect(offer(), isTrue));

    test('already allowed (or provisional) → never', () {
      expect(offer(status: AuthorizationStatus.authorized), isFalse);
      expect(offer(status: AuthorizationStatus.provisional), isFalse);
    });

    test('iOS refused once → never nag (system prompt cannot come back)', () {
      expect(offer(status: AuthorizationStatus.denied), isFalse);
    });

    test('Android 13+ reports « denied » before the first ask → offered', () {
      expect(offer(status: AuthorizationStatus.denied, isIOS: false), isTrue);
    });

    test('« Plus tard » is respected: 7 days apart, 3 times max', () {
      expect(offer(offers: 1, last: now.subtract(const Duration(days: 2))),
          isFalse);
      expect(offer(offers: 1, last: now.subtract(const Duration(days: 8))),
          isTrue);
      expect(offer(offers: 3, last: now.subtract(const Duration(days: 60))),
          isFalse);
    });
  });

  group('sheet', () {
    Future<bool?> open(WidgetTester tester, {required bool merchant}) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showNotificationSoftAskSheet(
                  context,
                  forMerchant: merchant),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('client: explains the benefit; « Activer » → true',
        (tester) async {
      await open(tester, merchant: false);
      expect(find.text('Ne ratez aucune offre'), findsOneWidget);
      await tester.tap(find.text('Activer les notifications'));
      await tester.pumpAndSettle();
    });

    testWidgets('merchant wording; « Plus tard » closes without asking',
        (tester) async {
      await open(tester, merchant: true);
      expect(find.text('Ne manquez aucun client'), findsOneWidget);
      await tester.tap(find.text('Plus tard'));
      await tester.pumpAndSettle();
      expect(find.text('Ne manquez aucun client'), findsNothing);
    });
  });
}
