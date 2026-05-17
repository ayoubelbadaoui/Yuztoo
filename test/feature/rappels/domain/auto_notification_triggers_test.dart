import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/rappels/domain/auto_notification_triggers.dart';
import 'package:flutter_yuztoo/feature/rappels/presentation/widgets/trigger_grid.dart';

void main() {
  test('triggerLabels matches AutoNotificationTriggers.triggerLabels', () {
    expect(triggerLabels, AutoNotificationTriggers.triggerLabels);
    expect(triggerLabels.length, 11);
  });

  test('birthday and inactive triggers are wired in cloud', () {
    expect(AutoNotificationTriggers.isWiredInCloud(
      AutoNotificationTriggers.birthday,
    ), isTrue);
    expect(AutoNotificationTriggers.isWiredInCloud(
      AutoNotificationTriggers.inactiveReturn,
    ), isTrue);
  });

  test('visitDetected is not wired yet', () {
    expect(AutoNotificationTriggers.isWiredInCloud(
      AutoNotificationTriggers.visitDetected,
    ), isFalse);
  });
}
