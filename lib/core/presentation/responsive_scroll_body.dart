import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Default max width for form-style content on phones / small tablets.
const double kResponsiveFormMaxWidth = 520;

/// Scrollable area with:
/// - Bottom padding for the software keyboard (`viewInsets`)
/// - Optional max content width so forms do not stretch edge-to-edge on Pro Max / iPad
///
/// Keyboard dismiss defaults to [ScrollViewKeyboardDismissBehavior.manual].
/// `onDrag` was removed as the default because on Samsung (and some other
/// Android devices) a tap on a [TextField] is often classified as a tiny
/// drag, so the keyboard opens then immediately dismisses — users report
/// "le clavier n'apparaît pas" on the onboarding name step.
class ResponsiveScrollBody extends StatelessWidget {
  const ResponsiveScrollBody({
    super.key,
    required this.child,
    this.horizontalPadding = 24,
    this.verticalPadding = 8,
    this.maxContentWidth = kResponsiveFormMaxWidth,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });

  final Widget child;
  final double horizontalPadding;
  final double verticalPadding;

  /// Set to 0 to use full width (minus horizontal padding only).
  final double maxContentWidth;

  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final innerWidth = math.max(
          0.0,
          constraints.maxWidth - 2 * horizontalPadding,
        );
        final cappedMax = maxContentWidth <= 0
            ? innerWidth
            : math.min(maxContentWidth, innerWidth);

        return SingleChildScrollView(
          keyboardDismissBehavior: keyboardDismissBehavior,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            verticalPadding + bottomInset,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: cappedMax > 0 ? cappedMax : innerWidth,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
