import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'city_catalog_repository.dart';
import 'crash_guard.dart';

// Web OAuth 2.0 Client ID (type 3) — required by google_sign_in v7+ for idToken on Android.
const _kGoogleWebClientId =
    '20266054150-bhrvh3cj1fnkgc6vhu7h340pr2j32ans.apps.googleusercontent.com';

// iOS OAuth 2.0 Client ID from GoogleService-Info.plist (CLIENT_ID key).
const _kGoogleIosClientId =
    '20266054150-omm1tiu719qq6rkbpvm6q5sposih75af.apps.googleusercontent.com';

/// Initializes Firebase and Google Sign-In once and exposes them as a FutureProvider.
final firebaseInitializationProvider = FutureProvider<void>((ref) async {
  await Firebase.initializeApp();
  // Crashlytics — wired right after Firebase init so any error during the
  // remaining bootstrap (Google Sign-In init, FCM token registration, …)
  // is captured. Collection is disabled in debug so iterating locally
  // doesn't pollute the dashboard with developer-induced crashes;
  // release builds (App Store / Play Store) collect normally so App
  // Review crashes and real-user incidents land in the console.
  // Error handlers themselves are installed by CrashGuard in main().
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  CrashGuard.attachContext();
  await signOutSessionRestoredByFreshInstall();
  // The iOS keychain persists Firebase Auth sessions across app reinstalls —
  // and even across server-side account deletion (e.g. the signup rollback
  // that removes an orphan user). A restored session whose account no longer
  // exists cannot refresh its token, so every Firestore call fails with
  // permission-denied. Detect that state at bootstrap and sign out so the
  // app starts clean instead of booting a dead session.
  final restoredUser = FirebaseAuth.instance.currentUser;
  if (restoredUser != null) {
    try {
      await restoredUser.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'user-disabled' ||
          e.code == 'invalid-user-token' ||
          e.code == 'user-token-expired') {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // Offline or transient failure — keep the session and let the app retry.
    }
  }
  // On iOS: pass clientId (iOS OAuth client) so the plugin reads from plist.
  // On Android: serverClientId is required so authenticate() returns a non-null idToken.
  try {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    await GoogleSignIn.instance.initialize(
      clientId: isIOS ? _kGoogleIosClientId : null,
      serverClientId: _kGoogleWebClientId,
    );
  } catch (e) {
    debugPrint('[GoogleSignIn] initialize error: $e');
  }
});

const _kInstallMarkerKey = 'yuztoo_install_marker_v1';

/// iOS keeps the Firebase Auth session in the keychain when the app is
/// deleted, so a reinstall opened straight into the previous account — often
/// an unfinished onboarding — instead of the welcome screen. App data
/// (SharedPreferences) *is* wiped on uninstall: no marker and no other saved
/// key means a fresh install, so the restored session is dropped.
///
/// Users updating the app already have saved keys (role cache, …): they only
/// get the marker and stay signed in.
@visibleForTesting
Future<void> signOutSessionRestoredByFreshInstall({
  FirebaseAuth? auth,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_kInstallMarkerKey)) return;
    try {
      final freshInstall = prefs.getKeys().isEmpty;
      final firebaseAuth = auth ?? FirebaseAuth.instance;
      if (freshInstall && firebaseAuth.currentUser != null) {
        await firebaseAuth.signOut();
      }
    } finally {
      // Always mark: a retry next launch would see saved keys and wrongly
      // treat the app as updated.
      await prefs.setBool(_kInstallMarkerKey, true);
    }
  } catch (e) {
    // Never block startup on this clean-up.
    debugPrint('[Auth] fresh-install check failed: $e');
  }
}

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

/// Shared geo.api.gouv.fr catalog (EPCI expansion for Découvrir, city pickers).
final cityCatalogRepositoryProvider = Provider<CityCatalogRepository>((ref) {
  final catalog = CityCatalogRepository(persistDepartmentLists: true);
  ref.onDispose(catalog.close);
  return catalog;
});
