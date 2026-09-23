import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors `_RootShellState.build`: an AnimatedSwitcher keyed per screen that
/// gets wrapped by the client-only LoyaltyCelebrationOverlay once auth flips
/// to Authenticated — which happens mid-OTP, before the profile is written.
class _ShellHarness extends StatefulWidget {
  const _ShellHarness({required this.useGlobalKey});

  final bool useGlobalKey;

  @override
  State<_ShellHarness> createState() => _ShellHarnessState();
}

class _ShellHarnessState extends State<_ShellHarness> {
  final GlobalKey _shellBodyKey = GlobalKey(debugLabel: 'shellBody');
  bool authenticatedClient = false;
  bool safeAreaWrapped = false;

  void signIn() => setState(() => authenticatedClient = true);
  void toggleSafeArea() => setState(() => safeAreaWrapped = !safeAreaWrapped);

  @override
  Widget build(BuildContext context) {
    Widget shellBody = AnimatedSwitcher(
      key: widget.useGlobalKey ? _shellBodyKey : null,
      duration: const Duration(milliseconds: 180),
      child: const KeyedSubtree(
        key: ValueKey<String>('otp'),
        child: _FakeOtpScreen(),
      ),
    );
    if (authenticatedClient) {
      shellBody = _FakeCelebrationOverlay(child: shellBody);
    }
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            safeAreaWrapped
                ? SafeArea(bottom: false, child: shellBody)
                : shellBody,
          ],
        ),
      ),
    );
  }
}

class _FakeCelebrationOverlay extends StatefulWidget {
  const _FakeCelebrationOverlay({required this.child});

  final Widget child;

  @override
  State<_FakeCelebrationOverlay> createState() =>
      _FakeCelebrationOverlayState();
}

class _FakeCelebrationOverlayState extends State<_FakeCelebrationOverlay> {
  @override
  Widget build(BuildContext context) => Stack(children: [widget.child]);
}

int _otpInitCount = 0;

class _FakeOtpScreen extends StatefulWidget {
  const _FakeOtpScreen();

  @override
  State<_FakeOtpScreen> createState() => _FakeOtpScreenState();
}

class _FakeOtpScreenState extends State<_FakeOtpScreen> {
  final TextEditingController code = TextEditingController();
  bool verifying = false;

  @override
  void initState() {
    super.initState();
    _otpInitCount++;
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(key: const Key('code'), controller: code),
        if (verifying) const Text('verifying'),
        TextButton(
          onPressed: () => setState(() => verifying = true),
          child: const Text('submit'),
        ),
      ],
    );
  }
}

Future<_ShellHarnessState> _typeCodeAndSubmit(
  WidgetTester tester, {
  required bool useGlobalKey,
}) async {
  _otpInitCount = 0;
  await tester.pumpWidget(_ShellHarness(useGlobalKey: useGlobalKey));
  await tester.enterText(find.byKey(const Key('code')), '750099');
  await tester.tap(find.text('submit'));
  await tester.pump();
  expect(find.text('verifying'), findsOneWidget);
  expect(_otpInitCount, 1);
  return tester.state<_ShellHarnessState>(find.byType(_ShellHarness));
}

void main() {
  testWidgets(
      'without a stable key, client sign-in mid-OTP recreates the OTP screen '
      '(the production bug)', (tester) async {
    final shell = await _typeCodeAndSubmit(tester, useGlobalKey: false);

    shell.signIn();
    await tester.pump();

    expect(_otpInitCount, 2);
    expect(find.text('verifying'), findsNothing);
    expect(
      tester.widget<TextField>(find.byKey(const Key('code'))).controller!.text,
      isEmpty,
    );
  });

  testWidgets(
      'with the shell body GlobalKey, client sign-in mid-OTP keeps the same '
      'OTP state (typed code + verifying spinner survive)', (tester) async {
    final shell = await _typeCodeAndSubmit(tester, useGlobalKey: true);

    shell.signIn();
    await tester.pump();

    expect(_otpInitCount, 1);
    expect(find.text('verifying'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byKey(const Key('code'))).controller!.text,
      '750099',
    );
  });

  testWidgets('the GlobalKey also survives the SafeArea wrapper toggling',
      (tester) async {
    final shell = await _typeCodeAndSubmit(tester, useGlobalKey: true);

    shell.toggleSafeArea();
    await tester.pump();
    shell.signIn();
    await tester.pump();
    shell.toggleSafeArea();
    await tester.pump();

    expect(_otpInitCount, 1);
    expect(find.text('verifying'), findsOneWidget);
  });
}
