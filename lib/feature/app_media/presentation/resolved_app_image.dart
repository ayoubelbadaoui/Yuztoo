import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../domain/app_media_slot.dart';

/// Loads a CMS catalog image when publication gate allows; otherwise [fallback].
///
/// Lazy: only fetches the network image when this widget builds and a URL exists.
/// Does not precache the whole catalog.
class ResolvedAppImage extends ConsumerWidget {
  const ResolvedAppImage({
    super.key,
    required this.slotId,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.clipOval = false,
    this.borderRadius,
  });

  final AppMediaSlotId slotId;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool clipOval;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUrl = ref.watch(resolvedAppMediaUrlProvider(slotId));

    return asyncUrl.when(
      loading: () => _box(fallback),
      error: (_, __) => _box(fallback),
      data: (url) {
        if (url == null || url.isEmpty) return _box(fallback);
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final cacheW =
            width != null ? (width! * dpr).round() : null;
        final image = Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: cacheW,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return fallback;
          },
        );
        return _box(_clip(image));
      },
    );
  }

  Widget _clip(Widget child) {
    if (clipOval) return ClipOval(child: child);
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _box(Widget child) {
    if (width == null && height == null) return child;
    return SizedBox(width: width, height: height, child: child);
  }
}
