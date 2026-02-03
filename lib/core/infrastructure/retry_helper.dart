import 'dart:async';

/// Helper class for retrying failed operations.
/// 
/// FIX HIGH 8: Retry mechanism for failed operations
class RetryHelper {
  /// Retry an operation with exponential backoff.
  /// 
  /// [operation] - The async operation to retry
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay before first retry (default: 1 second)
  /// [maxDelay] - Maximum delay between retries (default: 10 seconds)
  /// [retryOn] - Function to determine if error should be retried (default: retry on all errors)
  /// 
  /// Returns the result of the operation or throws the last error if all retries fail.
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 10),
    bool Function(Object error)? retryOn,
  }) async {
    int attempt = 0;
    Object? lastError;
    StackTrace? lastStackTrace;

    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;

        // Check if we should retry this error
        if (retryOn != null && !retryOn(e)) {
          // Error should not be retried, rethrow immediately
          throw e;
        }

        // If this was the last attempt, don't wait
        if (attempt >= maxRetries) {
          break;
        }

        // Calculate delay with exponential backoff
        final delay = Duration(
          milliseconds: (initialDelay.inMilliseconds * (1 << attempt))
              .clamp(0, maxDelay.inMilliseconds),
        );

        // Wait before retrying
        await Future.delayed(delay);
        attempt++;
      }
    }

    // All retries failed, throw the last error
    if (lastError != null) {
      Error.throwWithStackTrace(lastError, lastStackTrace ?? StackTrace.current);
    }
    throw StateError('Retry failed but no error was captured');
  }

  /// Check if an error is retryable (network errors, timeouts).
  static bool isRetryableError(Object error) {
    // Retry on timeout exceptions
    if (error is TimeoutException) {
      return true;
    }

    // Retry on network-related errors
    // You can add more specific error types here
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('unavailable');
  }
}

