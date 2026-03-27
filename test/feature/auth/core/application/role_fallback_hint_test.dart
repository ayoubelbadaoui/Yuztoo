import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/role_fallback_hint.dart';
import 'package:flutter_yuztoo/types.dart';

void main() {
  group('roleHintFromAuthUserData', () {
    test('primary_role merchant wins over client flags (activated client UI)', () {
      expect(
        roleHintFromAuthUserData(
          primaryRole: 'merchant',
          roles: <String, bool>{
            'client': true,
            'merchant': false,
            'provider': false,
          },
          roleString: 'client',
        ),
        UserRole.merchant,
      );
    });

    test('merchant roles map wins even if role string is wrong (reload / stale cache case)', () {
      expect(
        roleHintFromAuthUserData(
          roles: <String, bool>{
            'client': false,
            'merchant': true,
            'provider': true,
          },
          roleString: 'client',
        ),
        UserRole.merchant,
      );
    });

    test('client roles map when merchant is false', () {
      expect(
        roleHintFromAuthUserData(
          roles: <String, bool>{
            'client': true,
            'merchant': false,
            'provider': false,
          },
          roleString: 'merchant',
        ),
        UserRole.client,
      );
    });

    test('returns null when no roles map and role string is default client (use prefs next)', () {
      expect(
        roleHintFromAuthUserData(
          roles: null,
          roleString: 'client',
        ),
        isNull,
      );
    });

    test('merchant string without roles map (legacy)', () {
      expect(
        roleHintFromAuthUserData(
          roles: null,
          roleString: 'merchant',
        ),
        UserRole.merchant,
      );
    });
  });
}
