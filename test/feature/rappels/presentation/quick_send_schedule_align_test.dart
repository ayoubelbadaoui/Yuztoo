import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/rappels/presentation/widgets/quick_send_section.dart';

void main() {
  group('alignDateTimeToMinuteInterval', () {
    test('leaves aligned minutes unchanged', () {
      final dt = DateTime(2026, 5, 16, 14, 30);
      expect(alignDateTimeToMinuteInterval(dt, 5), dt);
    });

    test('rounds up to next 5-minute slot', () {
      final dt = DateTime(2026, 5, 16, 14, 32);
      expect(
        alignDateTimeToMinuteInterval(dt, 5),
        DateTime(2026, 5, 16, 14, 35),
      );
    });

    test('rolls hour when rounding past :55', () {
      final dt = DateTime(2026, 5, 16, 14, 57);
      expect(
        alignDateTimeToMinuteInterval(dt, 5),
        DateTime(2026, 5, 16, 15, 0),
      );
    });
  });
}
