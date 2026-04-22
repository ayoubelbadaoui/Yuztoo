import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Default max width for form-style content on phones / small tablets.
const double kResponsiveFormMaxWidth = 520;

/// Scrollable area with:
/// - Bottom padding for the software keyboard (`viewInsets`)
/// - Dismiss keyboard on drag
/// - Optional max content width so forms do not stretch edge-to-edge on Pro Max / iPad
class ResponsiveScrollBody extends StatelessWidget {
  const ResponsiveScrollBody({
    super.key,
    required this.child,
    this.horizontalPadding = 24,
    this.verticalPadding = 8,
    this.maxContentWidth = kResponsiveFormMaxWidth,
  });

  final Widget child;
  final double horizontalPadding;
  final double verticalPadding;

  /// Set to 0 to use full width (minus horizontal padding only).
  final double maxContentWidth;

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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
