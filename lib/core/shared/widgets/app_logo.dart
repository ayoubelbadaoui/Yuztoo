import 'package:flutter/material.dart';

/// Reusable app logo widget with multi-resolution PNG support.
///
/// Uses Flutter's built-in resolution-aware asset loading:
///   assets/branding/logo.png       → 1x  (333×333)
///   assets/branding/2.0x/logo.png  → 2x  (667×667)
///   assets/branding/3.0x/logo.png  → 3x  (1000×1000)
///
/// Flutter automatically picks the right resolution for the device.
/// PNG is used because the source SVG contains <filter>/<mask> elements
/// that crash flutter_svg on Android. Replace with SVG once you have a
/// clean, flat vector export (< 50 KB, no filters/masks/embedded PNGs).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.assetPath = 'assets/branding/logo.png',
    this.size = 80,
    this.fit = BoxFit.contain,
    this.fallback,
  });

  final String assetPath;
  final double size;
  final BoxFit fit;

  /// Widget shown when the asset can't load.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: fit,
        // Let Flutter pick 1x / 2x / 3x automatically
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: fallback ??
                  const Icon(Icons.location_on, size: 40),
            ),
          );
        },
      ),
    );
  }
}
