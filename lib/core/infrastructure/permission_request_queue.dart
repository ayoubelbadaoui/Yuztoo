import 'dart:async';

/// Runs OS permission prompts one at a time.
///
/// Android and iOS reject a second permission request while one is still on
/// screen ("A request for permissions is already running"). Startup fires
/// several (notifications, Bluetooth), so every prompt goes through here.
class PermissionRequestQueue {
  PermissionRequestQueue._();

  static Future<void> _tail = Future<void>.value();

  static Future<T> run<T>(Future<T> Function() request) {
    final result = _tail.then((_) => request());
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}
