import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logger/logger.dart';

/// Centralized logging service for infrastructure layer
/// Logs failures and errors with proper formatting
class LoggerService {
  static Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Handled errors never reach [FlutterError.onError] or the
  /// [PlatformDispatcher] hook wired in firebase_providers.dart, so without
  /// this bridge they are invisible in production — the console log only
  /// exists on the developer's machine.
  static bool _reportToCrashlytics = true;

  /// Context values under these keys identify a person and must not leave the
  /// device. They stay in the local console log, which is debug-only.
  static const Set<String> _piiKeys = {
    'phone',
    'phoneNumber',
    'email',
    'password',
    'token',
    'firstName',
    'lastName',
  };

  /// Silence all log output — call once in flutter_test_config.dart so
  /// expected-failure paths do not pollute test console output.
  static void muteForTests() {
    _logger = Logger(level: Level.off);
    _reportToCrashlytics = false;
  }

  /// Log an error with stack trace
  static void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _logger.e(
      message,
      error: error,
      stackTrace: stackTrace,
    );
    if (context != null && context.isNotEmpty) {
      _logger.d('Context: $context');
    }
    _recordNonFatal(message, error, stackTrace, context);
  }

  /// Mirrors a handled error into Crashlytics as a non-fatal so failure rates
  /// are measurable without putting diagnostics in front of the user.
  static void _recordNonFatal(
    String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  ) {
    if (!_reportToCrashlytics) return;
    try {
      unawaited(
        FirebaseCrashlytics.instance
            .recordError(
              error ?? message,
              stackTrace,
              reason: message,
              information: _redact(context),
              fatal: false,
            )
            // Reporting is best-effort: a logging call must never be the
            // reason a feature fails.
            .catchError((_) {}),
      );
    } catch (_) {
      // Firebase not initialized (unit tests, very early bootstrap).
    }
  }

  static List<Object> _redact(Map<String, dynamic>? context) {
    if (context == null || context.isEmpty) return const [];
    return context.entries
        .map((e) => '${e.key}=${_piiKeys.contains(e.key) ? '[redacted]' : e.value}')
        .toList(growable: false);
  }

  /// Log a failure (domain failures)
  static void logFailure(
    String failureType,
    String message, {
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _logger.w(
      '[$failureType] $message',
      error: cause,
      stackTrace: stackTrace,
    );
    if (context != null && context.isNotEmpty) {
      _logger.d('Context: $context');
    }
  }

  /// Log info messages
  static void logInfo(String message, {Map<String, dynamic>? context}) {
    _logger.i(message);
    if (context != null && context.isNotEmpty) {
      _logger.d('Context: $context');
    }
  }

  /// Log debug messages
  static void logDebug(String message, {Map<String, dynamic>? context}) {
    _logger.d(message);
    if (context != null && context.isNotEmpty) {
      _logger.d('Context: $context');
    }
  }
}

