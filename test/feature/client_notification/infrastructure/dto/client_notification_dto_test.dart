import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/client_notification/domain/entities/client_notification.dart';
import 'package:flutter_yuztoo/feature/client_notification/infrastructure/dto/client_notification_dto.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ClientNotificationDto type mapping — pins the wire vocabulary against
// the Cloud Function side (functions/src/index.ts:dailyBonExpirationScan
// writes 'bon_expiring' / 'bon_expired'). A drift here = silent
// mis-routing on tap (the deep-link falls through to the merchant
// storefront instead of opening Mes avantages), so these are the
// load-bearing tests.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('typeToString', () {
    test('maps each enum value to its wire string', () {
      expect(ClientNotificationDto.typeToString(ClientNotificationType.promotion),
          'promotion');
      expect(ClientNotificationDto.typeToString(ClientNotificationType.loyalty),
          'loyalty');
      expect(ClientNotificationDto.typeToString(ClientNotificationType.auto),
          'auto');
      expect(
          ClientNotificationDto.typeToString(ClientNotificationType.bonExpiring),
          'bon_expiring');
      expect(
          ClientNotificationDto.typeToString(ClientNotificationType.bonExpired),
          'bon_expired');
    });
  });

  group('round-trip via fromFirestore', () {
    DateTime now = DateTime(2026, 5, 8);

    Map<String, dynamic> rawDoc(String type) => {
          'client_id': 'u1',
          'merchant_id': 'm1',
          'merchant_name': 'Café',
          'type': type,
          'title': 'titre',
          'body': 'corps',
          'is_read': false,
          'created_at': null,
          if (type == 'promotion') 'promotion_id': 'p1',
        };

    ClientNotification toDomain(String type) {
      final dto = ClientNotificationDto(
        id: 'n1',
        clientId: rawDoc(type)['client_id'] as String,
        merchantId: rawDoc(type)['merchant_id'] as String,
        merchantName: rawDoc(type)['merchant_name'] as String,
        type: type,
        title: rawDoc(type)['title'] as String,
        body: rawDoc(type)['body'] as String,
        isRead: rawDoc(type)['is_read'] as bool,
        createdAt: now,
        promotionId: rawDoc(type)['promotion_id'] as String?,
      );
      return dto.toDomain();
    }

    test('promotion stays promotion', () {
      expect(toDomain('promotion').type, ClientNotificationType.promotion);
    });

    test('auto stays auto', () {
      expect(toDomain('auto').type, ClientNotificationType.auto);
    });

    test('loyalty stays loyalty', () {
      expect(toDomain('loyalty').type, ClientNotificationType.loyalty);
    });

    test('bon_expiring resolves to bonExpiring', () {
      expect(toDomain('bon_expiring').type,
          ClientNotificationType.bonExpiring);
    });

    test('bon_expired resolves to bonExpired', () {
      expect(toDomain('bon_expired').type,
          ClientNotificationType.bonExpired);
    });

    test('unknown wire values map to auto (generic alert → storefront tap)', () {
      expect(toDomain('mystery_future').type, ClientNotificationType.auto);
    });

    test('general maps to auto', () {
      expect(toDomain('general').type, ClientNotificationType.auto);
    });
  });
}
