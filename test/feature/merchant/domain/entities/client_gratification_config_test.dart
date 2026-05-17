import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/client_gratification_config.dart';

void main() {
  const config = ClientGratificationConfig(
    habituelThreshold: 3,
    vipThreshold: 10,
    inactifAfterDays: 60,
  );

  test('segmentKeyFor respects custom thresholds', () {
    expect(
      config.segmentKeyFor(validatedPassages: 0, daysSinceLastVisit: 0),
      'nouveau',
    );
    expect(
      config.segmentKeyFor(validatedPassages: 3, daysSinceLastVisit: 10),
      'habitue',
    );
    expect(
      config.segmentKeyFor(validatedPassages: 10, daysSinceLastVisit: 10),
      'vip',
    );
    expect(
      config.segmentKeyFor(validatedPassages: 99, daysSinceLastVisit: 61),
      'inactif',
    );
  });

  test('labelForPassages uses custom labels', () {
    const custom = ClientGratificationConfig(
      nouveauLabel: 'Première visite',
      habituelLabel: 'Régulier',
      vipLabel: 'Star',
      habituelThreshold: 2,
      vipThreshold: 5,
    );
    expect(custom.labelForPassages(1), 'Première visite');
    expect(custom.labelForPassages(2), 'Régulier');
    expect(custom.labelForPassages(5), 'Star');
  });
}
