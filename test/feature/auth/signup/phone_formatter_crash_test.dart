import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/auth/signup/presentation/utils/phone_formatter.dart';

void main() {
  group('formatPhoneForDisplay', () {
    void expectNoCrash(String phone) {
      expect(
        () => PhoneFormatter.formatPhoneForDisplay(phone),
        returnsNormally,
        reason: 'should not throw for $phone',
      );
    }

    test('short and partial international numbers', () {
      for (final p in [
        '+216',
        '+2161',
        '+21612',
        '+33',
        '+336',
        '+33612345678',
        '+212612345678',
        '+21',
        '+2',
        '+',
      ]) {
        expectNoCrash(p);
      }
    });

    test('partial +21 prefix does not throw (was Tunisia RangeError)', () {
      expect(() => PhoneFormatter.formatPhoneForDisplay('+21'), returnsNormally);
    });

    test('formats France E.164', () {
      expect(
        PhoneFormatter.formatPhoneForDisplay('+33612345678'),
        '+33 61 23 45 67 8',
      );
    });

    test('formats Morocco E.164', () {
      expect(
        PhoneFormatter.formatPhoneForDisplay('+212612345678'),
        '+212 6 12 34 56 78',
      );
    });
  });
}
