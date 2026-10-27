import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/infrastructure/deferred_vitrine_link.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? clipboardText;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.getData':
          if (clipboardText == null) return null;
          return <String, dynamic>{'text': clipboardText};
        case 'Clipboard.setData':
          final args = call.arguments;
          if (args is Map) {
            clipboardText = args['text'] as String?;
          }
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('DeferredVitrineLink.consumeOnce', () {
    test('recovers merchant id from clipboard https vitrine URL', () async {
      clipboardText =
          'https://yuztoo.web.app/vitrine/1mIcTfERGtaqOvweQ6LoAu9WUZE2';

      final id = await DeferredVitrineLink.consumeOnce();
      expect(id, '1mIcTfERGtaqOvweQ6LoAu9WUZE2');
      // Cleared after successful recovery.
      expect(clipboardText, '');

      // One-shot: second call returns null even if clipboard is filled again.
      clipboardText =
          'https://yuztoo.web.app/vitrine/anotherMerchantId99';
      expect(await DeferredVitrineLink.consumeOnce(), isNull);
    });

    test('ignores unrelated clipboard text', () async {
      clipboardText = 'hello world';
      expect(await DeferredVitrineLink.consumeOnce(), isNull);
    });

    test('ignores invalid merchant id in clipboard URL', () async {
      clipboardText = 'https://yuztoo.web.app/vitrine/__x__';
      expect(await DeferredVitrineLink.consumeOnce(), isNull);
    });

    test('skips when already checked in prefs', () async {
      SharedPreferences.setMockInitialValues({
        'deferred_vitrine_link_checked_v1': true,
      });
      clipboardText = 'https://yuztoo.web.app/vitrine/shouldNotRecover';
      expect(await DeferredVitrineLink.consumeOnce(), isNull);
    });
  });
}
