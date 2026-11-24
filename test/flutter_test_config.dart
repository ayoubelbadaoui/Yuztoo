import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/infrastructure/logger_service.dart';

/// Global test configuration executed by `flutter test` before any test file.
///
/// Silences [LoggerService] so that intentional error-path tests (e.g.
/// ownership-denied scenarios) do not pollute the test console with red stacks.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() {
    LoggerService.muteForTests();
    // Google Fonts loads fonts asynchronously; the engine then sends a
    // `fontsChange` system message whose relayout frame is scheduled after
    // the test's widget tree is gone → "An animation is still running even
    // after the widget tree was disposed". Tests never need system font
    // changes, so drop that message (other system messages are dropped too:
    // memory pressure etc. are irrelevant under test).
    TestWidgetsFlutterBinding.ensureInitialized();
    SystemChannels.system.setMessageHandler((_) async => null);
  });
  await testMain();
}
