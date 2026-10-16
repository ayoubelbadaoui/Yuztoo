import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Last-resort error handling, installed first thing in `main()` so errors
/// thrown before Firebase finishes initializing are not lost.
///
/// None of these handlers terminate the app: framework and async errors are
/// recorded and the app keeps running, and a widget that throws while
/// building renders a neutral placeholder instead of the grey release box.
///
/// Also enriches every Crashlytics report with who (uid, role), where
/// (route, app state) and what happened just before (breadcrumbs).
class CrashGuard {
  CrashGuard._();

  static AppLifecycleListener? _lifecycle;
  static StreamSubscription<User?>? _authSub;

  static void install() {
    FlutterError.onError = (details) {
      if (kDebugMode) FlutterError.presentError(details);
      _record(details.exception, details.stack, reason: details.context?.toString());
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _record(error, stack, reason: 'uncaught async error');
      return true;
    };

    if (kReleaseMode) {
      ErrorWidget.builder = (_) => const _BrokenWidgetPlaceholder();
    }

    _lifecycle ??= AppLifecycleListener(
      onStateChange: (state) {
        setKey('app_state', state.name);
        breadcrumb('lifecycle ${state.name}');
      },
    );
  }

  /// Call once Firebase is initialized: static keys + uid tracking.
  static void attachContext() {
    setKey('flavor', appFlavor ?? 'none');
    setKey('build_mode', kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug'));
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        _crashlytics((c) => c.setUserIdentifier(user?.uid ?? ''));
        setKey('signed_in', user != null);
        setKey('auth_provider', user?.providerData.firstOrNull?.providerId ?? 'none');
      },
      onError: (Object _) {},
    );
  }

  static void setRole(String role) {
    setKey('role', role);
    breadcrumb('role $role');
  }

  static void setRoute(String route) {
    setKey('route', route);
    breadcrumb('route $route');
  }

  /// Shows up in the "Logs" tab of the next report (last 64 KB are kept).
  static void breadcrumb(String message) =>
      _crashlytics((c) => c.log(message));

  static void setKey(String key, Object value) =>
      _crashlytics((c) => c.setCustomKey(key, value));

  // Recorded as non-fatal: the process survives these, so labelling them
  // fatal inflates the crash rate and hides real native crashes.
  static void _record(Object error, StackTrace? stack, {String? reason}) {
    if (Firebase.apps.isEmpty) {
      debugPrint('[CrashGuard] $reason: $error');
      return;
    }
    _crashlytics(
      (c) => c.recordError(error, stack, reason: reason, fatal: false),
    );
  }

  static void _crashlytics(Future<void> Function(FirebaseCrashlytics) call) {
    if (Firebase.apps.isEmpty) return;
    try {
      call(FirebaseCrashlytics.instance).catchError((_) {});
    } catch (_) {}
  }
}

/// Route names are mostly null here (plain MaterialPageRoute), so the route
/// type plus the stack depth is the best stable label available.
class CrashlyticsNavigatorObserver extends NavigatorObserver {
  int _depth = 0;

  void _report(String action, Route<dynamic>? route) {
    final name = route?.settings.name;
    CrashGuard.setRoute(
      '$action ${name ?? route?.runtimeType ?? 'unknown'} depth=$_depth',
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _depth++;
    _report('push', route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _depth = _depth > 0 ? _depth - 1 : 0;
    _report('pop->', previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _report('replace', newRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _depth = _depth > 0 ? _depth - 1 : 0;
  }
}

class _BrokenWidgetPlaceholder extends StatelessWidget {
  const _BrokenWidgetPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
