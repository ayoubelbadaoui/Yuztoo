import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/infrastructure/logger_service.dart';

/// Global test configuration executed by `flutter test` before any test file.
///
/// Silences [LoggerService] so that intentional error-path tests (e.g.
/// ownership-denied scenarios) do not pollute the test console with red stacks.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() {
    LoggerService.muteForTests();
  });
  await testMain();
}
