import 'package:flutter/material.dart';

/// Left-edge horizontal swipe that triggers [onBack], for shell screens that
/// are not real Navigator routes (so iOS Cupertino swipe-back never fires).
///
/// Only a ~20px strip on the left edge listens, so horizontal scroll views
/// elsewhere on the page are unaffected.
class EdgeSwipeBack extends StatefulWidget {
  const EdgeSwipeBack({
    super.key,
    required this.enabled,
    required this.onBack,
    required this.child,
    this.edgeWidth = 20,
    this.distanceThreshold = 60,
    this.velocityThreshold = 600,
  });

  final bool enabled;
  final VoidCallback onBack;
  final Widget child;

  /// Width of the hit strip along the left edge.
  final double edgeWidth;

  /// Minimum drag distance (logical px) to commit a back.
  final double distanceThreshold;

  /// Minimum fling velocity (px/s) to commit a back.
  final double velocityThreshold;

  @override
  State<EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<EdgeSwipeBack> {
  double _dragDx = 0;

  void _reset() => _dragDx = 0;

  void _maybeCommit(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    final shouldPop =
        _dragDx >= widget.distanceThreshold || v >= widget.velocityThreshold;
    _reset();
    if (shouldPop) widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: widget.edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _reset(),
            onHorizontalDragUpdate: (details) {
              // Only accumulate left-to-right motion.
              if (details.delta.dx > 0) {
                _dragDx += details.delta.dx;
              } else if (details.delta.dx < 0) {
                _dragDx = (_dragDx + details.delta.dx).clamp(0, double.infinity);
              }
            },
            onHorizontalDragEnd: _maybeCommit,
            onHorizontalDragCancel: _reset,
          ),
        ),
      ],
    );
  }
}
