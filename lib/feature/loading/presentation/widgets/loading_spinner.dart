import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Spinner widget: rotating arc + static ring.
///
/// Layer 1 – static ring (r=72, stroke-width 1, opacity 0.2)
/// Layer 2 – rotating + dashing ring (3s rotation, 2s dash animation)
///
/// The bird-in-pin logo used to sit in the centre; it was removed per
/// product call ("no need to show the image when opening the page, only
/// the loading that exists already"). The ring-only spinner keeps the
/// same brand-gold colour and timing so the splash still feels on-brand.
class LoadingSpinner extends StatefulWidget {
  const LoadingSpinner({super.key});

  @override
  State<LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<LoadingSpinner>
    with TickerProviderStateMixin {
  late final AnimationController _rotation;
  late final AnimationController _dash;
  late final Animation<double> _dashCurved;

  @override
  void initState() {
    super.initState();

    _rotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _dash = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _dashCurved =
        CurvedAnimation(parent: _dash, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _rotation.dispose();
    _dash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Layer 1: static ring
          CustomPaint(
            size: const Size(160, 160),
            painter: _StaticRingPainter(),
          ),
          // Layer 2: rotating + dashing ring
          AnimatedBuilder(
            animation: _rotation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotation.value * 2 * math.pi,
                child: AnimatedBuilder(
                  animation: _dashCurved,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(160, 160),
                      painter:
                          _DashRingPainter(progress: _dashCurved.value),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── painters ─────────────────────────────────────────────────────────────────

class _StaticRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MerchantColors.gold.withValues(alpha: 0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      72,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashRingPainter extends CustomPainter {
  _DashRingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const r = 72.0;
    const circ = 452.4;
    final center = Offset(size.width / 2, size.height / 2);

    double visibleLen;
    double offset;
    if (progress <= 0.5) {
      final t = progress / 0.5;
      visibleLen = 1.6 + 224.0 * t;
      offset = -75.2 * t;
    } else {
      final t = (progress - 0.5) / 0.5;
      visibleLen = 225.6 - 224.0 * t;
      offset = -75.2 - 377.2 * t;
    }

    final sweepAngle = (visibleLen / circ) * 2 * math.pi;
    final startAngle = -math.pi / 2 + (offset / circ) * 2 * math.pi;

    final paint = Paint()
      ..color = MerchantColors.gold
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_DashRingPainter old) => old.progress != progress;
}

