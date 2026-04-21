import 'package:flutter/material.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Three pulsing gold dots at the bottom of the loading screen.
class DecorativeDots extends StatelessWidget {
  const DecorativeDots({super.key});

  @override
  Widget build(BuildContext context) {
    // Respect device safe area so dots don't hide behind the home indicator.
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: bottomPadding + 32,
      left: 0,
      right: 0,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PulsingDot(baseOpacity: 0.3, delay: Duration.zero),
          SizedBox(width: 20),
          _PulsingDot(baseOpacity: 0.8, delay: Duration(milliseconds: 200)),
          SizedBox(width: 20),
          _PulsingDot(baseOpacity: 0.3, delay: Duration(milliseconds: 400)),
        ],
      ),
    );
  }
}

/// A single 12×12 gold dot that pulses (opacity 0.4→1→0.4).
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.baseOpacity, required this.delay});
  final double baseOpacity;
  final Duration delay;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.4)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(_ctrl);

    if (widget.delay == Duration.zero) {
      _ctrl.repeat();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.repeat();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) =>
          Opacity(opacity: _opacity.value, child: child),
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: MerchantColors.gold,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

