import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/e_fidelite/application/e_fidelite_providers.dart';
import 'package:flutter_yuztoo/feature/merchant/application/providers.dart'
    as merchant_providers;
import 'package:flutter_yuztoo/feature/merchant/domain/entities/loyalty_program_config.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant_storefront_link.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/repositories/merchant_repository.dart';
import 'package:flutter_yuztoo/feature/merchant/infrastructure/merchant_repository_provider.dart';
import 'package:flutter_yuztoo/feature/merchant_settings/application/providers.dart';
import 'package:flutter_yuztoo/feature/merchant_settings/presentation/merchant_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingMerchantRepository implements MerchantRepository {
  int loyaltyStandaloneWrites = 0;

  static const merchant = Merchant(
    id: 'm1',
    ownerUid: 'u1',
    name: 'Shop',
    email: 'shop@test.com',
    phone: '+33600000000',
    city: 'Paris',
    loyaltyEnabled: false,
  );

  @override
  Future<Result<Merchant>> updateMerchant({
    required String merchantId,
    String? displayName,
    String? description,
    List<String>? categories,
    String? logoUrl,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? websiteUrl,
    String? bannerUrl,
    List<String>? newsImageUrls,
    String? status,
    Map<String, dynamic>? hours,
    String? welcomeGiftDescription,
    bool? rappelsAutoClientValidation,
    bool? rappelsAutoPassageValidation,
    bool? passageCooldownEnabled,
    LoyaltyProgramConfig? loyaltyProgram,
    bool? messagingEnabled,
    bool? notificationsAutoEnabled,
    bool? galerieEnabled,
    bool? loyaltyEnabledStandalone,
    String? merchantType,
    String? categoryId,
    String? subcategoryTitle,
    bool clearCityField = false,
    List<MerchantStorefrontLink>? storefrontLinks,
  }) async {
    if (loyaltyEnabledStandalone != null) {
      loyaltyStandaloneWrites++;
    }
    return const Right(merchant);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'merchant_settings.control_popup_seen.m1': true,
    });
  });

  testWidgets(
    'Fidélité ON without saved program navigates to E-Fidélité without persist',
    (tester) async {
      final repo = _RecordingMerchantRepository();
      String? navigated;
      late ProviderContainer container;

      container = ProviderContainer(
        overrides: [
          merchant_providers.currentMerchantForOwnerProvider.overrideWith(
            (ref) async => _RecordingMerchantRepository.merchant,
          ),
          currentMerchantIdProvider.overrideWith((ref) => 'm1'),
          merchantRepositoryProvider.overrideWithValue(repo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MerchantSettingsScreen(
              onNavigate: (route) => navigated = route,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final fideliteLabel = find.text('Fidélité');
      expect(fideliteLabel, findsOneWidget);

      final fideliteRow = find.ancestor(
        of: fideliteLabel,
        matching: find.byType(Row),
      );
      final toggleGesture = find.descendant(
        of: fideliteRow,
        matching: find.byType(GestureDetector),
      );
      expect(toggleGesture, findsOneWidget);

      await tester.ensureVisible(toggleGesture);
      await tester.tap(toggleGesture);
      await tester.pumpAndSettle();

      expect(repo.loyaltyStandaloneWrites, 0);
      expect(navigated, 'e-fidelite');
      expect(container.read(pendingLoyaltyConfigurationProvider), isTrue);

      container.dispose();
    },
  );
}
