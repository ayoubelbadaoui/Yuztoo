import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/domain/core/either.dart';
import 'package:flutter_yuztoo/core/domain/core/failure.dart';
import 'package:flutter_yuztoo/core/domain/core/result.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/client_onboarding_routing.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/merchant_onboarding_routing.dart';
import 'package:flutter_yuztoo/feature/auth/core/application/onboarding_completion_cache.dart';
import 'package:flutter_yuztoo/feature/auth/core/domain/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _NetworkFailure extends AppFailure {
  const _NetworkFailure() : super('offline');
}

/// Each call pops the next scripted answer; `null` = hang forever.
class _ScriptedRepo implements UserRepository {
  _ScriptedRepo(this.answers);
  final List<Future<Result<bool?>> Function()?> answers;
  int calls = 0;

  Future<Result<bool?>> _next() {
    final f = answers[calls < answers.length ? calls : answers.length - 1];
    calls++;
    return f == null ? Completer<Result<bool?>>().future : f();
  }

  @override
  Future<Result<bool?>> isClientOnboardingCompleted(String uid) => _next();

  @override
  Future<Result<bool?>> isMerchantOnboardingCompleted(String uid) => _next();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<Result<bool?>> Function() ok(bool? v) =>
    () async => Right<AppFailure, bool?>(v);
Future<Result<bool?>> Function() fails() =>
    () async => const Left<AppFailure, bool?>(_NetworkFailure());
Future<Result<bool?>> Function() throws() =>
    () async => throw StateError('socket closed');

const _short = Duration(milliseconds: 50);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('client: which screen after launch', () {
    test('completed in Firestore → home, and remembered on device', () async {
      final repo = _ScriptedRepo([ok(true)]);
      expect(await clientOnboardingCompletedFromFirestore(repo, 'u'), isTrue);
      expect(await OnboardingCompletionCache.wasCompleted('client', 'u'),
          isTrue);
    });

    test('pending in Firestore → onboarding (even if device remembers)',
        () async {
      await OnboardingCompletionCache.markCompleted('client', 'u');
      final repo = _ScriptedRepo([ok(false)]);
      expect(await clientOnboardingCompletedFromFirestore(repo, 'u'), isFalse);
    });

    test('offline at launch, finished before on this phone → home, '
        'not « Bienvenue » again', () async {
      await OnboardingCompletionCache.markCompleted('client', 'u');
      final repo = _ScriptedRepo([fails()]);
      expect(await clientOnboardingCompletedFromFirestore(repo, 'u'), isTrue);
      expect(repo.calls, 2, reason: 'retried once before falling back');
    });

    test('offline right after reinstall (nothing remembered) → onboarding',
        () async {
      final repo = _ScriptedRepo([fails()]);
      expect(await clientOnboardingCompletedFromFirestore(repo, 'u'), isFalse);
    });

    test('Firestore read hangs → answer within the timeout, never stuck on '
        'splash', () async {
      await OnboardingCompletionCache.markCompleted('client', 'u');
      final repo = _ScriptedRepo([null]);
      final sw = Stopwatch()..start();
      final done = await clientOnboardingCompletedFromFirestore(repo, 'u',
          timeout: _short);
      expect(done, isTrue);
      expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('transient failure then success → uses the real answer', () async {
      final repo = _ScriptedRepo([throws(), ok(false)]);
      expect(await clientOnboardingCompletedFromFirestore(repo, 'u'), isFalse);
    });

    test('legacy / non-client account (null) → not forced into onboarding',
        () async {
      final repo = _ScriptedRepo([ok(null)]);
      expect(await clientOnboardingCompletedFromFirestore(repo, 'u'), isTrue);
    });

    test('memory is per account: another user on the same phone is not '
        'skipped', () async {
      await OnboardingCompletionCache.markCompleted('client', 'alice');
      final repo = _ScriptedRepo([fails()]);
      expect(await clientOnboardingCompletedFromFirestore(repo, 'bob'),
          isFalse);
    });
  });

  group('merchant: which screen after launch', () {
    test('offline at launch, shop already created on this phone → '
        'storefront, never the creation wizard', () async {
      await OnboardingCompletionCache.markCompleted('merchant', 'm');
      final repo = _ScriptedRepo([fails()]);
      expect(await merchantOnboardingCompletedFromFirestore(repo, 'm'),
          isTrue);
    });

    test('client memory does not count as merchant onboarding', () async {
      await OnboardingCompletionCache.markCompleted('client', 'm');
      final repo = _ScriptedRepo([fails()]);
      expect(await merchantOnboardingCompletedFromFirestore(repo, 'm'),
          isFalse);
    });

    test('hanging read is bounded', () async {
      final repo = _ScriptedRepo([null]);
      final done = await merchantOnboardingCompletedFromFirestore(repo, 'm',
          timeout: _short);
      expect(done, isFalse);
    });

    test('not a merchant yet (null) → wizard', () async {
      final repo = _ScriptedRepo([ok(null)]);
      expect(await merchantOnboardingCompletedFromFirestore(repo, 'm'),
          isFalse);
    });
  });
}
