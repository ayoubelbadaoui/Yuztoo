import 'logger_service.dart';

extension TolerantMapping<T> on Iterable<T> {
  /// Like `map(...).toList()`, but an element whose conversion throws is
  /// skipped (and logged) instead of failing the whole list — one malformed
  /// Firestore document must not blank a feed for every user who sees it.
  List<R> mapSkippingInvalid<R>(R Function(T item) convert, {String? label}) {
    final out = <R>[];
    for (final item in this) {
      try {
        out.add(convert(item));
      } catch (e, st) {
        LoggerService.logError(
          'Skipped malformed document${label == null ? '' : ' ($label)'}',
          error: e,
          stackTrace: st,
        );
      }
    }
    return out;
  }
}
