import 'package:logger/logger.dart';

/// Centralized logging service for infrastructure layer
/// Logs failures and errors with proper formatting
class LoggerService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

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

