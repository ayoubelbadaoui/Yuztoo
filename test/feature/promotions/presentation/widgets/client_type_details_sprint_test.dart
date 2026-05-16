import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/promotions/domain/entities/promotion.dart';
import 'package:flutter_yuztoo/feature/promotions/presentation/widgets/client_type_details.dart';

void main() {
  group('ClientTypeDetails premium — mal corrigé S4', () {
    testWidgets('shows segment chips but not fake date filter rows',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientTypeDetails(
              clientType: ClientType.premium,
              selectedSegments: const {'vip'},
              selectedDistanceIndex: 0,
              onSegmentToggled: (_) {},
              onDistanceChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('VIP'), findsOneWidget);
      expect(find.text('Soutien'), findsOneWidget);
      expect(find.text('Filtres avancés bientôt disponibles'), findsOneWidget);
      expect(find.textContaining('Clients actifs depuis'), findsNothing);
      expect(find.textContaining('15/01/2025'), findsNothing);
    });
  });
}
