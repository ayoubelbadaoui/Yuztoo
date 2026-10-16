import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/infrastructure/permission_request_queue.dart';

void main() {
  test('runs requests one at a time, in call order', () async {
    final log = <String>[];
    final first = Completer<void>();

    final a = PermissionRequestQueue.run(() async {
      log.add('a start');
      await first.future;
      log.add('a end');
      return 'a';
    });
    final b = PermissionRequestQueue.run(() async {
      log.add('b start');
      return 'b';
    });

    await Future<void>.delayed(Duration.zero);
    expect(log, ['a start']);

    first.complete();
    expect(await a, 'a');
    expect(await b, 'b');
    expect(log, ['a start', 'a end', 'b start']);
  });

  test('a failed request does not block the next one', () async {
    final failing = PermissionRequestQueue.run<String>(
      () async => throw StateError('already running'),
    );
    final next = PermissionRequestQueue.run(() async => 'ok');

    await expectLater(failing, throwsStateError);
    expect(await next, 'ok');
  });
}
