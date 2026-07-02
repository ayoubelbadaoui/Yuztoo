import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/providers.dart'
    as auth_providers;
import 'package:flutter_yuztoo/feature/auth/core/domain/entities/auth_user.dart';
import 'package:flutter_yuztoo/feature/promotions/application/providers.dart';
import 'package:flutter_yuztoo/feature/promotions/presentation/promotions_management_screen.dart';

void main() {
  group('PromotionsManagementScreen — mal corrigé S2', () {
    testWidgets('does not show duplicate Notifications automatiques CTA',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auth_providers.authStateProvider.overrideWith(
              (ref) => const Authenticated(
                AuthUser(id: 'merchant-1', email: 'm@test.com', role: 'merchant'),
              ),
            ),
            merchantPromotionsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: PromotionsManagementScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Notifications automatiques'), findsNothing);
      expect(
        find.text('Relancez vos clients au bon moment'),
        findsNothing,
      );
    });
  });
}
