import 'package:flutter/material.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Two radial-gradient orbs that pulse in the background.
///
/// CSS:
///   orb-1 – top:10%, left:50% translateX(-50%), 300×300, gold 15%→transparent
///   orb-2 – bottom:10%, right:-50px, 200×200, gold 10%→transparent
///   both: pulse 4s ease-in-out infinite (orb-2 delayed 0.5s)
class BackgroundOrbs extends StatelessWidget {
  const BackgroundOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        _SingleOrb(
          topFraction: 0.10,
          centerHorizontally: true,
          diameter: 300,
          gradientOpacity: 0.15,
          delay: Duration.zero,
        ),
        _SingleOrb(
          bottomFraction: 0.10,
          rightOffset: -50,
          diameter: 200,
          gradientOpacity: 0.10,
          delay: Duration(milliseconds: 500),
        ),
      ],
    );
  }
}

class _SingleOrb extends StatefulWidget {
  const _SingleOrb({
    this.topFraction,
    this.bottomFraction,
    this.centerHorizontally = false,
    this.rightOffset,
    required this.diameter,
    required this.gradientOpacity,
    required this.delay,
  });

  final double? topFraction;
  final double? bottomFraction;
  final bool centerHorizontally;
  final double? rightOffset;
  final double diameter;
  final double gradientOpacity;
  final Duration delay;

  @override
  State<_SingleOrb> createState() => _SingleOrbState();
}

class _SingleOrbState extends State<_SingleOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));
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
    final screen = MediaQuery.sizeOf(context);
    double? top;
    double? bottom;
    double? left;
    double? right;

    if (widget.topFraction != null) {
      top = screen.height * widget.topFraction!;
    }
    if (widget.bottomFraction != null) {
      bottom = screen.height * widget.bottomFraction!;
    }
    if (widget.centerHorizontally) {
      left = (screen.width - widget.diameter) / 2;
    }
    if (widget.rightOffset != null) {
      right = widget.rightOffset!;
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (context, child) =>
            Opacity(opacity: _opacity.value, child: child),
        child: Container(
          width: widget.diameter,
          height: widget.diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                MerchantColors.gold
                    .withValues(alpha: widget.gradientOpacity),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7],
            ),
          ),
        ),
      ),
    );
  }
}

