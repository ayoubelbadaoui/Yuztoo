import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../firebase_options.dart';

// Web OAuth 2.0 Client ID (type 3) — required by google_sign_in v7+ for idToken on Android.
const _kGoogleWebClientId =
    '20266054150-bhrvh3cj1fnkgc6vhu7h340pr2j32ans.apps.googleusercontent.com';

// iOS OAuth 2.0 Client ID from GoogleService-Info.plist (CLIENT_ID key).
const _kGoogleIosClientId =
    '20266054150-omm1tiu719qq6rkbpvm6q5sposih75af.apps.googleusercontent.com';

/// Initializes Firebase and Google Sign-In once and exposes them as a FutureProvider.
final firebaseInitializationProvider = FutureProvider<void>((ref) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Crashlytics — wired right after Firebase init so any error during the
  // remaining bootstrap (Google Sign-In init, FCM token registration, …)
  // is captured. Collection is disabled in debug so iterating locally
  // doesn't pollute the dashboard with developer-induced crashes;
  // release builds (TestFlight + App Store) collect normally so App
  // Review crashes and real-user incidents land in the console.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  // Forward all Flutter framework errors. recordFlutterError preserves
  // the original FlutterErrorDetails (library, context, silent flag)
  // so the dashboard groups them sensibly.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  // Forward platform-dispatcher errors (uncaught async errors that
  // bubble past the framework) as fatal, since they would otherwise
  // crash the isolate. Returning true tells the dispatcher we handled
  // the error so it doesn't double-log to stderr.
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
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

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);
