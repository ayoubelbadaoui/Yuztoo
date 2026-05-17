import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/oauth_identity_helpers.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';

void main() {
  group('splitOAuthDisplayName', () {
    test('splits full name', () {
      final r = splitOAuthDisplayName('Marie Dupont');
      expect(r.firstName, 'Marie');
      expect(r.lastName, 'Dupont');
    });

    test('single token → first name only', () {
      final r = splitOAuthDisplayName('AppleUser');
      expect(r.firstName, 'AppleUser');
      expect(r.lastName, isNull);
    });
  });

  group('oauthIdentityForCreateUserDocument', () {
    test('includes Google photo URL', () {
      const user = AuthUser(
        id: 'u1',
        email: 'a@b.com',
        displayName: 'Jean Martin',
        photoUrl: 'https://lh3.googleusercontent.com/a/photo.jpg',
        role: 'client',
      );
      final o = oauthIdentityForCreateUserDocument(user);
      expect(o.photoUrl, contains('googleusercontent'));
      expect(o.firstName, 'Jean');
      expect(o.lastName, 'Martin');
    });

    test('Apple user has names but no photo URL', () {
      const user = AuthUser(
        id: 'u2',
        email: 'c@d.com',
        displayName: 'Lucas Bernard',
        photoUrl: null,
        role: 'client',
      );
      final o = oauthIdentityForCreateUserDocument(user);
      expect(o.photoUrl, isNull);
      expect(o.firstName, 'Lucas');
      expect(o.lastName, 'Bernard');
    });
  });
}
