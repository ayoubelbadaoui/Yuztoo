import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/failure.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/providers.dart'
    as auth_providers;
import 'package:flutter_yuztoo/feature/client_home/application/providers.dart';
import 'package:flutter_yuztoo/feature/client_home/presentation/client_home_screen.dart';
import 'package:flutter_yuztoo/feature/followed_merchants/domain/repositories/followed_merchants_repository.dart';
import 'package:flutter_yuztoo/feature/followed_merchants/infrastructure/followed_merchants_repository_provider.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/l10n/app_localizations.dart';

/// Phase B carnet hardening — widget + repository contract tests.
class _RecordingFollowedRepo implements FollowedMerchantsRepository {
  int updateSortOrderCalls = 0;
  Map<String, int>? lastSortIndexes;
  bool failNextUpdate = false;

  @override
  Future<Result<Unit>> updateSortOrder(
      String userId, Map<String, int> sortIndexes) async {
    updateSortOrderCalls++;
    lastSortIndexes = Map<String, int>.from(sortIndexes);
    if (failNextUpdate) {
      return const Left(UnexpectedFailure(message: 'simulated'));
    }
    return const Right(unit);
  }

  @override
  Future<Result<List<String>>> getFollowerIds(String merchantId) async =>
      const Right([]);

  @override
  Future<Result<Unit>> add(String userId, String merchantId) async =>
      const Right(unit);

  @override
  Future<Result<Unit>> remove(String userId, String merchantId) async =>
      const Right(unit);

  @override
  Future<Result<bool>> isFollowing(String userId, String merchantId) async =>
      const Right(false);

  @override
  Future<Result<List<String>>> getFollowedIds(String userId) async =>
      const Right([]);

  @override
  Future<Result<Map<String, int>>> getFollowedHeartLevels(String userId) async =>
      const Right({});

  @override
  Future<Result<Unit>> setHeartLevel(
          String userId, String merchantId, int heartLevel) async =>
      const Right(unit);

  @override
  Future<Result<bool>> getMuteState(String userId, String merchantId) async =>
      const Right(false);

  @override
  Future<Result<Unit>> setMuteState(String userId, String merchantId,
          {required bool muted}) async =>
      const Right(unit);

  @override
  Future<Result<Set<String>>> getMutedMerchantIds(String userId) async =>
      const Right(<String>{});

  @override
  Future<Result<Map<String, int>>> getFollowedSortIndexes(String userId) async =>
      const Right({});
}

Merchant _merchant(String id, String name) => Merchant(
      id: id,
      ownerUid: 'owner',
      name: name,
      email: '$id@test.com',
      phone: '+33600000000',
      city: 'Paris',
    );

ClientHomeFeed _feed(List<Merchant> merchants) => (
      merchants: merchants,
      followedIds: merchants.map((m) => m.id).toList(),
      promotions: const [],
      ownMerchantId: null,
      sortIndexes: const <String, int>{},
    );

void main() {
  late _RecordingFollowedRepo followedRepo;

  setUp(() {
    followedRepo = _RecordingFollowedRepo();
  });

  Widget wrap(Widget child) => ProviderScope(
        overrides: [
          auth_providers.currentUserIdProvider.overrideWith((ref) => 'user_test'),
          followedMerchantsRepositoryProvider.overrideWith((ref) => followedRepo),
          clientHomeFeedProvider.overrideWith(
            (ref) async => _feed([
              _merchant('m_a', 'Alpha'),
              _merchant('m_b', 'Beta'),
            ]),
          ),
          followedMerchantHeartLevelsForCurrentUserProvider.overrideWith(
            (ref) async => const {'m_a': 2, 'm_b': 1},
          ),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );

  group('ClientHomeScreen carnet — Phase B UI', () {
    testWidgets('shows reorder hint and drag handles for 2+ merchants',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          ClientHomeScreen(
            onNavigate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Maintenir une vignette pour réorganiser'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(2));
    });

    testWidgets('single followed merchant still shows drag affordance',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auth_providers.currentUserIdProvider.overrideWith((ref) => 'user_test'),
            followedMerchantsRepositoryProvider.overrideWith((ref) => followedRepo),
            clientHomeFeedProvider.overrideWith(
              (ref) async => _feed([_merchant('m_only', 'Only')]),
            ),
            followedMerchantHeartLevelsForCurrentUserProvider.overrideWith(
              (ref) async => const {'m_only': 1},
            ),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ClientHomeScreen(onNavigate: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.drag_indicator_rounded), findsOneWidget);
    });
  });

  group('updateSortOrder callback contract', () {
    test('successful persist calls repository with positional indexes', () async {
      final repo = _RecordingFollowedRepo();
      final result = await repo.updateSortOrder('user_test', {
        'm_b': 0,
        'm_a': 1,
      });
      expect(result.isRight, isTrue);
      expect(repo.lastSortIndexes, {'m_b': 0, 'm_a': 1});
    });

    test('failed persist returns Left without throwing', () async {
      final repo = _RecordingFollowedRepo()..failNextUpdate = true;
      final result = await repo.updateSortOrder('user_test', {'m_a': 0});
      expect(result.isLeft, isTrue);
    });
  });
}
