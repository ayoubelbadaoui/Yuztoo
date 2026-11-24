import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/utils/profile_placeholders.dart';

void main() {
  test('legacy example values are treated as unset', () {
    expect(ProfilePlaceholders.isPlaceholder('www.votresite.com'), isTrue);
    expect(ProfilePlaceholders.isPlaceholder(' +33123456789 '), isTrue);
    expect(ProfilePlaceholders.isPlaceholder(''), isTrue);
    expect(ProfilePlaceholders.isPlaceholder(null), isTrue);
    expect(ProfilePlaceholders.clean('www.votresite.com'), '');
  });

  test('real values are kept and trimmed', () {
    expect(ProfilePlaceholders.isPlaceholder('www.cadence.fr'), isFalse);
    expect(ProfilePlaceholders.clean('  06 11 22 33 44 '), '06 11 22 33 44');
  });
}
