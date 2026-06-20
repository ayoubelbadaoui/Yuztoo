import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_yuztoo/feature/auth/core/application/oauth_post_signup_routing.dart';
import 'package:flutter_yuztoo/types.dart';

void main() {
  group('resolveOAuthCompletionRole', () {
    test('explicit merchant shell role wins', () {
      expect(
        resolveOAuthCompletionRole(
          shellRole: UserRole.merchant,
          intendedRole: UserRole.client,
        ),
        UserRole.merchant,
      );
    });

    test('falls back to intended role when shell defaulted to client', () {
      expect(
        resolveOAuthCompletionRole(
          shellRole: UserRole.client,
          intendedRole: UserRole.merchant,
        ),
        UserRole.merchant,
      );
    });

    test('defaults to client when no intended role', () {
      expect(
        resolveOAuthCompletionRole(
          shellRole: UserRole.client,
          intendedRole: null,
        ),
        UserRole.client,
      );
    });
  });
}
