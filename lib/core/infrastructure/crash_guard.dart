import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Last-resort error handling, installed first thing in `main()` so errors
/// thrown before Firebase finishes initializing are not lost.
///
/// None of these handlers terminate the app: framework and async errors are
/// recorded and the app keeps running, and a widget that throws while
/// building renders a neutral placeholder instead of the grey release box.
class CrashGuard {
  CrashGuard._();

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
  }

  // Recorded as non-fatal: the process survives these, so labelling them
  // fatal inflates the crash rate and hides real native crashes.
  static void _record(Object error, StackTrace? stack, {String? reason}) {
    if (Firebase.apps.isEmpty) {
      debugPrint('[CrashGuard] $reason: $error');
      return;
    }
    try {
      FirebaseCrashlytics.instance
          .recordError(error, stack, reason: reason, fatal: false)
          .catchError((_) {});
    } catch (_) {}
  }
}

class _BrokenWidgetPlaceholder extends StatelessWidget {
  const _BrokenWidgetPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
