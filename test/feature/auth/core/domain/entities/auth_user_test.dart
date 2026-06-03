import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthUser role-resolution invariants.
//
// [hasClientRole] / [hasMerchantRole] are the source of truth for any UI
// that has to decide "does this user already own the OTHER role?". These
// must not be confused with [isMerchant], which short-circuits on
// `primary_role` and was the cause of the regression where the
// "Créer un compte pro" CTA stayed visible after a primary-client user
// finished merchant onboarding.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  AuthUser u({
    Map<String, bool>? roles,
    String? primaryRole,
    String role = 'client',
  }) =>
      AuthUser(
        id: 'u1',
        roles: roles,
        primaryRole: primaryRole,
        role: role,
      );

  group('hasMerchantRole / hasClientRole — roles map is source of truth', () {
    test('roles map flags both true → both helpers return true', () {
      final user = u(
        roles: const {'client': true, 'merchant': true},
        primaryRole: 'client',
      );
      expect(user.hasClientRole, isTrue);
      expect(user.hasMerchantRole, isTrue);
      expect(user.hasBothRoles, isTrue);
    });

    test('only client flag true → hasMerchantRole is false', () {
      final user = u(
        roles: const {'client': true, 'merchant': false},
        primaryRole: 'client',
      );
      expect(user.hasClientRole, isTrue);
      expect(user.hasMerchantRole, isFalse);
      expect(user.hasBothRoles, isFalse);
    });

    test('only merchant flag true → hasClientRole is false', () {
      final user = u(
        roles: const {'client': false, 'merchant': true},
        primaryRole: 'merchant',
      );
      expect(user.hasClientRole, isFalse);
      expect(user.hasMerchantRole, isTrue);
      expect(user.hasBothRoles, isFalse);
    });

    test(
        'roles map wins over primary_role — primary=client + merchant flag '
        'true still reports merchant role (regression scenario)', () {
      final user = u(
        roles: const {'client': true, 'merchant': true},
        primaryRole: 'client',
      );
      // [isMerchant] short-circuits to false on primary=client. The new
      // helper must NOT inherit that behaviour, otherwise the
      // "Créer un compte pro" CTA stays visible to a dual-profile user.
      expect(user.isMerchant, isFalse);
      expect(user.hasMerchantRole, isTrue);
    });
  });

  group('hasMerchantRole / hasClientRole — fallback resolution', () {
    test('roles map missing → primary_role drives both helpers', () {
      final merchantPrimary = u(primaryRole: 'merchant', role: 'client');
      expect(merchantPrimary.hasMerchantRole, isTrue);
      expect(merchantPrimary.hasClientRole, isFalse);

      final clientPrimary = u(primaryRole: 'client', role: 'client');
      expect(clientPrimary.hasMerchantRole, isFalse);
      expect(clientPrimary.hasClientRole, isTrue);
    });

    test('roles map and primary_role missing → legacy role string used', () {
      final merchantLegacy = u(role: 'merchant');
      expect(merchantLegacy.hasMerchantRole, isTrue);
      expect(merchantLegacy.hasClientRole, isFalse);

      final clientLegacy = u(role: 'client');
      expect(clientLegacy.hasMerchantRole, isFalse);
      expect(clientLegacy.hasClientRole, isTrue);
    });
  });

  group('hasBothRoles', () {
    test('returns false when only one role flag is set', () {
      final clientOnly =
          u(roles: const {'client': true, 'merchant': false});
      expect(clientOnly.hasBothRoles, isFalse);

      final merchantOnly =
          u(roles: const {'client': false, 'merchant': true});
      expect(merchantOnly.hasBothRoles, isFalse);
    });

    test('returns true when both role flags are set, regardless of primary',
        () {
      for (final primary in ['client', 'merchant', null]) {
        final user = u(
          roles: const {'client': true, 'merchant': true},
          primaryRole: primary,
        );
        expect(user.hasBothRoles, isTrue,
            reason: 'failed for primary=$primary');
      }
    });
  });
}
