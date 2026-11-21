import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feature/app_media/domain/app_media_slot.dart';
import '../../../feature/app_media/presentation/resolved_app_image.dart';

/// Reusable app logo with multi-resolution PNG fallback + remote CMS override.
///
/// Bundle (always available):
///   assets/branding/logo.png       → 1x  (333×333)
///   assets/branding/2.0x/logo.png  → 2x  (667×667)
///   assets/branding/3.0x/logo.png  → 3x  (1000×1000)
///
/// Remote `brand.logo` is used only when Firebase release is live (or preview
/// for the selected test account). Otherwise the bundled asset is shown.
class AppLogo extends ConsumerWidget {
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

  /// Widget shown when neither remote nor asset can load.
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
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
    );

    return ResolvedAppImage(
      slotId: AppMediaSlotId.brandLogo,
      width: size,
      height: size,
      fit: fit,
      fallback: asset,
    );
  }
}
