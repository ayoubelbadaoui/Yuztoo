part of 'firebase_auth_repository.dart';

mixin _FirebaseAuthRepositorySession on _FirebaseAuthRepositoryBase {
  Stream<Result<AuthUser?>> watchAuthState() async* {
    // Use userChanges() stream which automatically handles Firebase Auth persistence.
    // Root issue: on some devices/builds, userChanges() may not emit immediately on cold start,
    // which can leave the app stuck on splash waiting for the first auth state.
    //
    // Root fix: force an initial check with a short timeout, without emitting a false logout.
    // - If we have a currentUser -> emit immediately.
    // - If not, wait briefly for userChanges().first, then re-check currentUser before emitting null.
    String? lastEmittedUid;
    bool hasEmittedAny = false;

    firebase.User? initialUser = _auth.currentUser;
    if (initialUser == null) {
      try {
        initialUser =
            await _auth.userChanges().first.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        // No emission yet - re-check (Firebase may have restored session)
        initialUser = _auth.currentUser;
      } catch (_) {
        initialUser = _auth.currentUser;
      }

      // If we still look logged out, wait a tiny bit and re-check to avoid transient null.
      if (initialUser == null) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        initialUser = _auth.currentUser;
      }
    }

    // Emit initial state using the same mapping logic as the stream loop.
    // This guarantees the app won't get stuck on splash waiting for a first emission.
    lastEmittedUid = initialUser?.uid;
    hasEmittedAny = true;
    if (initialUser == null) {
      yield const Right<AuthFailure, AuthUser?>(null);
    } else {
      try {
        DocumentSnapshot<Map<String, dynamic>>? profileDoc;
        try {
          profileDoc = await _firestore
              .collection('users')
              .doc(initialUser.uid)
              .get()
              .timeout(const Duration(seconds: 5));
        } on TimeoutException {
          profileDoc = null;
        } catch (_) {
          profileDoc = null;
        }

        final mapped = await _profileToAuthResult(initialUser, profileDoc);
        yield mapped;
        if (mapped.isLeft) {
          lastEmittedUid = null;
        }
      } catch (_) {
        // Any error while building the initial user -> fallback to FirebaseAuth user only
        final dto = AuthUserDto.fromFirebase(initialUser);
        yield Right<AuthFailure, AuthUser?>(dto.toDomain());
      }
    }

    await for (final userEvent in _auth.userChanges()) {
      // ROOT FIX:
      // FirebaseAuth.userChanges() can transiently emit `null` during token refresh,
      // app lifecycle transitions, or provider initialization.
      // If Firebase still has a non-null currentUser, we should NOT emit an
      // unauthenticated state (it causes UI "logout flicker").
      final user = userEvent ?? _auth.currentUser;

      // Skip duplicate emissions: same uid as last emitted (prevents duplicate emits)
      // But allow: null -> user, user -> null, or user -> different user
      final newUid = user?.uid;
      if (hasEmittedAny && newUid == lastEmittedUid) {
        continue;
      }
      lastEmittedUid = newUid;
      hasEmittedAny = true;

      if (user == null) {
        yield const Right<AuthFailure, AuthUser?>(null);
        continue;
      }

      try {
        // Try to fetch Firestore profile with timeout to handle delays gracefully
        // If Firestore is slow or fails, use fallback data from Firebase Auth user
        DocumentSnapshot<Map<String, dynamic>>? profileDoc;
        try {
          profileDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 5));
        } on TimeoutException {
          // Timeout is not an error - just use fallback data
          profileDoc = null;
        } catch (e) {
          // Any Firestore error - use fallback data
          profileDoc = null;
        }

        final mapped = await _profileToAuthResult(user, profileDoc);
        yield mapped;
        if (mapped.isLeft) {
          lastEmittedUid = null;
        }
      } on firebase.FirebaseAuthException catch (e) {
        // Only yield error for actual auth errors, not Firestore delays
        // For Firestore issues, use fallback data
        if (e.code == 'network-request-failed') {
          // Network error - use fallback data from Firebase Auth
          final dto = AuthUserDto.fromFirebase(user);
          yield Right<AuthFailure, AuthUser?>(dto.toDomain());
        } else {
          yield Left<AuthFailure, AuthUser?>(
              _mapAuthException(e, StackTrace.current));
        }
      } catch (e) {
        // Any other error (including Firestore timeouts/errors) - use fallback
        // Don't show errors for Firestore delays, just use Firebase Auth data
        final dto = AuthUserDto.fromFirebase(user);
        yield Right<AuthFailure, AuthUser?>(dto.toDomain());
      }
    }
  }

  @override
  Future<Result<AuthUser?>> reloadCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const Right<AuthFailure, AuthUser?>(null);
      }
      try {
        await user.reload();
      } catch (_) {
        // Non-fatal — still refetch Firestore below.
      }
      final fresh = _auth.currentUser ?? user;

      DocumentSnapshot<Map<String, dynamic>>? profileDoc;
      try {
        profileDoc = await _firestore
            .collection('users')
            .doc(fresh.uid)
            .get()
            .timeout(const Duration(seconds: 5));
      } on TimeoutException {
        profileDoc = null;
      } catch (_) {
        profileDoc = null;
      }

      return await _profileToAuthResult(fresh, profileDoc);
    } on firebase.FirebaseAuthException catch (e, st) {
      return Left<AuthFailure, AuthUser?>(_mapAuthException(e, st));
    } catch (e, st) {
      return Left<AuthFailure, AuthUser?>(
        AuthUnexpectedFailure(cause: e, stackTrace: st),
      );
    }
  }
}
