import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/utils/oauth_profile_photo.dart';

void main() {
  group('isUsableOAuthProfilePhotoUrl', () {
    test('accepts https URLs', () {
      expect(
        isUsableOAuthProfilePhotoUrl('https://lh3.googleusercontent.com/a/abc'),
        isTrue,
      );
    });

    test('rejects empty and non-http', () {
      expect(isUsableOAuthProfilePhotoUrl(null), isFalse);
      expect(isUsableOAuthProfilePhotoUrl(''), isFalse);
      expect(isUsableOAuthProfilePhotoUrl('file:///tmp/x.jpg'), isFalse);
    });
  });
}
