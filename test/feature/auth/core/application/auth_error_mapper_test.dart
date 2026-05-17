import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/auth_error_mapper.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/auth_failure.dart';

void main() {
  group('AuthErrorMapper', () {
    test('displayMessage returns specific SMS failure text', () {
      const failure = AuthUnexpectedFailure(
        message:
            'Impossible d\'envoyer le code SMS (code: invalid-phone-number).',
      );

      expect(
        AuthErrorMapper.displayMessage(failure),
        contains('invalid-phone-number'),
      );
    });

    test('displayMessage never returns empty for generic AuthUnexpectedFailure',
        () {
      const failure = AuthUnexpectedFailure();

      expect(AuthErrorMapper.displayMessage(failure), isNotEmpty);
    });

    test('displayMessage maps network failures', () {
      const failure = AuthNetworkFailure();

      expect(
        AuthErrorMapper.displayMessage(failure),
        contains('réseau'),
      );
    });
  });
}
