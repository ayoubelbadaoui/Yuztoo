import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/shared/widgets/keyboard_dismiss_on_tap.dart';

void main() {
  group('KeyboardDismissOnTap', () {
    testWidgets('tap outside a focused TextField unfocuses it', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: KeyboardDismissOnTap(
            child: Scaffold(
              body: Column(
                children: [
                  TextField(
                    key: const Key('field'),
                    focusNode: focusNode,
                  ),
                  const SizedBox(
                    key: Key('outside'),
                    height: 200,
                    width: double.infinity,
                    child: Text('outside'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('field')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.tap(find.byKey(const Key('outside')));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('tapping the TextField itself keeps focus', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: KeyboardDismissOnTap(
            child: Scaffold(
              body: TextField(
                key: const Key('field'),
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('field')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // Second tap on the same field must not clear focus.
      await tester.tap(find.byKey(const Key('field')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('MaterialApp.builder wrapper (same as main.dart) dismisses',
        (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => KeyboardDismissOnTap(
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: Column(
              children: [
                TextField(key: const Key('field'), focusNode: focusNode),
                const SizedBox(height: 120),
                const Text('tap-me', key: Key('outside')),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('field')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.tap(find.byKey(const Key('outside')));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('dismisses focus inside a modal bottom sheet', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => KeyboardDismissOnTap(
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('open-sheet'),
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => SizedBox(
                      height: 280,
                      child: Column(
                        children: [
                          TextField(
                            key: const Key('sheet-field'),
                            focusNode: focusNode,
                          ),
                          const SizedBox(height: 80),
                          const Text('sheet-outside', key: Key('sheet-outside')),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open-sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sheet-field')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.tap(find.byKey(const Key('sheet-outside')));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('buttons under the wrapper still receive taps', (tester) async {
      var pressed = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: KeyboardDismissOnTap(
            child: Scaffold(
              body: ElevatedButton(
                key: const Key('btn'),
                onPressed: () => pressed++,
                child: const Text('Press'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('btn')));
      await tester.pump();
      expect(pressed, 1);
    });
  });
}
