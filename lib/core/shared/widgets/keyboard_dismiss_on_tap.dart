import 'package:flutter/material.dart';

/// Dismisses the software keyboard when the user taps outside a text field.
///
/// Wrap the app (or a screen subtree). Uses [HitTestBehavior.translucent] so
/// buttons, lists, and fields still receive their own taps.
class KeyboardDismissOnTap extends StatelessWidget {
  const KeyboardDismissOnTap({super.key, required this.child});

  final Widget child;

  static void unfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: unfocus,
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
