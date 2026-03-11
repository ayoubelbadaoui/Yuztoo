import 'package:flutter/material.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Sliding progress bar (180×4).
///
/// CSS: slideProgress 2.5s ease-in-out infinite
///   0% { width: 0% }  50% { width: 100% }  100% { width: 0% }
class LoadingProgressBar extends StatefulWidget {
  const LoadingProgressBar({super.key});

  @override
  State<LoadingProgressBar> createState() => _LoadingProgressBarState();
}

class _LoadingProgressBarState extends State<LoadingProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fill;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _fill = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 180,
        height: 4,
        color: MerchantColors.gold.withValues(alpha: 0.2),
        alignment: Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: _fill,
          builder: (context, child) {
            return FractionallySizedBox(
              widthFactor: _fill.value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: MerchantColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

