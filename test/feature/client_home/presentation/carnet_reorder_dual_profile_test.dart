/// God-level tests for the carnet drag-and-drop fix (claim 3).
///
/// Root bug: `_CarnetListState.onReorder` used `oldIndex + reorderOffset`
/// arithmetic which assumed the own-merchant is always at `_ordered[0]`.
/// This is not guaranteed — the provider feed can return merchants in any order.
///
/// Fix: rebuild `_ordered` from the reorderable subset + pinned own-merchant
/// instead of relying on a fixed offset.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/providers.dart'
    as auth_providers;
import 'package:flutter_yuztoo/feature/client_home/application/providers.dart';
import 'package:flutter_yuztoo/feature/client_home/presentation/client_home_screen.dart';
import 'package:flutter_yuztoo/feature/followed_merchants/domain/repositories/followed_merchants_repository.dart';
import 'package:flutter_yuztoo/feature/followed_merchants/infrastructure/followed_merchants_repository_provider.dart';
import 'package:flutter_yuztoo/feature/merchant/domain/entities/merchant.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/promotions/domain/entities/promotion.dart';
import 'package:flutter_yuztoo/l10n/app_localizations.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Merchant _m(String id, String name) => Merchant(
      id: id,
      ownerUid: id == 'own' ? 'owner-uid' : 'other-uid',
      name: name,
      email: '$id@test.com',
      phone: '+33600000000',
      city: 'Paris',
    );

/// Fake repo that captures every `updateSortOrder` call.
class _CapturingFollowedRepo implements FollowedMerchantsRepository {
  final List<Map<String, int>> calls = [];

  @override
  Stream<List<String>> watchFollowedIds(String userId) =>
      Stream<List<String>>.value(const <String>[]);

  @override
  Future<Result<Unit>> updateSortOrder(
      String userId, Map<String, int> sortIndexes) async {
    calls.add(Map<String, int>.from(sortIndexes));
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
  Future<Result<Map<String, int>>> getFollowedHeartLevels(
          String userId) async =>
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
  Future<Result<Map<String, int>>> getFollowedSortIndexes(
          String userId) async =>
      const Right({});
}

// ─── Test algorithm ───────────────────────────────────────────────────────────

/// Pure implementation of the fixed reorder algorithm, mirroring
/// `_CarnetListState.onReorder` so we can unit-test the logic
/// independently of Flutter widgets.
Map<String, int> _applyReorder({
  required List<String> orderedIds,
  required String? ownMerchantId,
  required int oldIndex,
  required int newIndex,
}) {
  var ni = newIndex;
  if (ni > oldIndex) ni--;

  final workingList = orderedIds
      .where((id) => id != ownMerchantId)
      .toList();
  final item = workingList.removeAt(oldIndex);
  workingList.insert(ni, item);

  final showPinned =
      ownMerchantId != null && orderedIds.contains(ownMerchantId);
  final newOrdered = showPinned
      ? [ownMerchantId, ...workingList]
      : workingList;

  final reorderable = newOrdered
      .where((id) => id != ownMerchantId)
      .toList();
  return {
    for (var i = 0; i < reorderable.length; i++) reorderable[i]: i,
  };
}

// ─── Widget helper ────────────────────────────────────────────────────────────

Widget _buildScreen({
  required List<Merchant> merchants,
  required String? ownMerchantId,
  required _CapturingFollowedRepo repo,
}) {
  final feed = (
    merchants: merchants,
    followedIds: merchants.map((m) => m.id).toList(),
    promotions: const <Promotion>[],
    ownMerchantId: ownMerchantId,
    sortIndexes: const <String, int>{},
  );

  return ProviderScope(
    overrides: [
      auth_providers.currentUserIdProvider.overrideWith((ref) => 'user_test'),
      followedMerchantsRepositoryProvider.overrideWith((ref) => repo),
      clientHomeFeedProvider.overrideWith((ref) => Stream.value(feed)),
      followedMerchantHeartLevelsForCurrentUserProvider.overrideWith(
        (ref) async => const <String, int>{},
      ),
    ],
    child: MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ClientHomeScreen(onNavigate: (_) {}),
    ),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── Pure algorithm — no Flutter widget needed ──────────────────────────────

  group('_applyReorder (pure logic)', () {
    test(
        'no dual-profile: moves index 0 to end → correct sort indexes',
        () {
      // [a, b, c] → drag a to end → [b, c, a]
      final result = _applyReorder(
        orderedIds: ['a', 'b', 'c'],
        ownMerchantId: null,
        oldIndex: 0,
        newIndex: 3,
      );
      expect(result, {'b': 0, 'c': 1, 'a': 2});
    });

    test(
        'no dual-profile: moves last item to front → correct sort indexes',
        () {
      // [a, b, c] → drag c to front → [c, a, b]
      final result = _applyReorder(
        orderedIds: ['a', 'b', 'c'],
        ownMerchantId: null,
        oldIndex: 2,
        newIndex: 0,
      );
      expect(result, {'c': 0, 'a': 1, 'b': 2});
    });

    test(
        'dual-profile, ownMerchant at index 0: reorders followers correctly',
        () {
      // ordered = [own, a, b, c]  reorderable = [a, b, c]
      // drag a (idx 0) to end → reorderable becomes [b, c, a]
      final result = _applyReorder(
        orderedIds: ['own', 'a', 'b', 'c'],
        ownMerchantId: 'own',
        oldIndex: 0,
        newIndex: 3,
      );
      expect(result, {'b': 0, 'c': 1, 'a': 2});
    });

    test(
        'dual-profile, ownMerchant at index 2 (BUG SCENARIO): still correct',
        () {
      // ordered = [a, b, own, c] — ownMerchant is NOT at index 0
      // reorderable = [a, b, c]
      // drag a (idx 0) to after c → [b, c, a]
      final result = _applyReorder(
        orderedIds: ['a', 'b', 'own', 'c'],
        ownMerchantId: 'own',
        oldIndex: 0,
        newIndex: 3,
      );
      expect(result, {'b': 0, 'c': 1, 'a': 2});
    });

    test(
        'dual-profile, ownMerchant at last position: reorder still excludes it',
        () {
      // ordered = [a, b, c, own]  reorderable = [a, b, c]
      // drag b (idx 1) to front → [b, a, c]
      final result = _applyReorder(
        orderedIds: ['a', 'b', 'c', 'own'],
        ownMerchantId: 'own',
        oldIndex: 1,
        newIndex: 0,
      );
      expect(result, {'b': 0, 'a': 1, 'c': 2});
    });

    test('ownMerchant never appears in persisted sort indexes', () {
      final result = _applyReorder(
        orderedIds: ['own', 'x', 'y', 'z'],
        ownMerchantId: 'own',
        oldIndex: 0,
        newIndex: 2,
      );
      expect(result.containsKey('own'), isFalse);
    });

    test('two-item swap produces exact inverse order', () {
      final result = _applyReorder(
        orderedIds: ['alpha', 'beta'],
        ownMerchantId: null,
        oldIndex: 0,
        newIndex: 2,
      );
      expect(result, {'beta': 0, 'alpha': 1});
    });

    test('ReorderableListView newIndex adjustment: newIndex > oldIndex is decremented', () {
      // Mirrors the `if (newIndex > oldIndex) newIndex--;` in Flutter's onReorder
      // Moving index 0 → 2 means "after slot 2", but adjusted to slot 1.
      // [a, b, c]: move a to slot 2 → adjusted to 1 → [b, a, c]
      final result = _applyReorder(
        orderedIds: ['a', 'b', 'c'],
        ownMerchantId: null,
        oldIndex: 0,
        newIndex: 2,
      );
      expect(result, {'b': 0, 'a': 1, 'c': 2});
    });

    test('no-op reorder (same slot) produces unchanged indexes', () {
      // drag index 1 to slot 1 (no visible movement) → [a, b, c] unchanged
      final result = _applyReorder(
        orderedIds: ['a', 'b', 'c'],
        ownMerchantId: null,
        oldIndex: 1,
        newIndex: 1,
      );
      expect(result, {'a': 0, 'b': 1, 'c': 2});
    });

    test('single-item list reorder is a no-op', () {
      final result = _applyReorder(
        orderedIds: ['solo'],
        ownMerchantId: null,
        oldIndex: 0,
        newIndex: 1,
      );
      expect(result, {'solo': 0});
    });
  });

  // ── Widget smoke tests ─────────────────────────────────────────────────────

  group('CarnetList dual-profile widget', () {
    testWidgets(
        'dual-profile: own merchant is pinned above reorderable list',
        (tester) async {
      final repo = _CapturingFollowedRepo();
      await tester.pumpWidget(
        _buildScreen(
          merchants: [
            _m('own', 'Mon Commerce'),
            _m('a', 'Alpha Café'),
            _m('b', 'Beta Boulangerie'),
          ],
          ownMerchantId: 'own',
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      // The pinned own-merchant tile must appear.
      expect(find.text('Mon Commerce'), findsOneWidget);
      // The reorderable followers must also appear.
      expect(find.text('Alpha Café'), findsOneWidget);
      expect(find.text('Beta Boulangerie'), findsOneWidget);
      // Reorder hint must be visible (> 0 reorderable items).
      expect(find.text('Maintenir une vignette pour réorganiser'),
          findsOneWidget);
    });

    testWidgets(
        'dual-profile with only own merchant: no reorder list rendered',
        (tester) async {
      final repo = _CapturingFollowedRepo();
      await tester.pumpWidget(
        _buildScreen(
          merchants: [_m('own', 'Mon Commerce')],
          ownMerchantId: 'own',
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Own merchant tile visible.
      expect(find.text('Mon Commerce'), findsOneWidget);
      // No reorder hint since no followers below.
      expect(
        find.text('Maintenir une vignette pour réorganiser'),
        findsNothing,
      );
    });

    testWidgets(
        'non-dual-profile: no pinned section, all merchants reorderable',
        (tester) async {
      final repo = _CapturingFollowedRepo();
      await tester.pumpWidget(
        _buildScreen(
          merchants: [
            _m('a', 'Alpha'),
            _m('b', 'Beta'),
            _m('c', 'Gamma'),
          ],
          ownMerchantId: null,
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
      expect(find.text('Maintenir une vignette pour réorganiser'),
          findsOneWidget);
    });
  });
}
