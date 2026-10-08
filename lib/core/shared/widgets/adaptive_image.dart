import 'package:flutter/material.dart';

/// Full-width image whose height follows the picture's own aspect ratio, so
/// square, portrait and landscape photos are all shown whole (never cropped).
///
/// Very tall images are capped at [maxHeight] and letterboxed on
/// [backgroundColor].
class AdaptiveImage extends StatelessWidget {
  const AdaptiveImage({
    super.key,
    required this.image,
    required this.maxHeight,
    this.backgroundColor = Colors.transparent,
    this.errorBuilder,
  });

  final ImageProvider image;
  final double maxHeight;
  final Color backgroundColor;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Image(
          image: image,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: errorBuilder,
        ),
      ),
    );
  }
}
