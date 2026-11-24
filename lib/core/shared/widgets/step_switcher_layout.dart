import 'package:flutter/widgets.dart';

/// [AnimatedSwitcher.layoutBuilder] for step-by-step flows (onboarding).
///
/// Same stack as the default layout, but the step that is fading out ignores
/// taps. Otherwise a quick double tap on « Suivant » lands on the previous
/// step's button during the 250 ms transition and skips a step.
Widget stepSwitcherLayout(Widget? currentChild, List<Widget> previousChildren) {
  return Stack(
    alignment: Alignment.center,
    children: <Widget>[
      for (final child in previousChildren) IgnorePointer(child: child),
      if (currentChild != null) currentChild,
    ],
  );
}
