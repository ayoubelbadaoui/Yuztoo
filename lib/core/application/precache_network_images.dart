import 'package:flutter/material.dart';

/// Warms the image cache for HTTP(S) URLs so banners and grids pop in together.
void precacheHttpImages(BuildContext context, Iterable<String?> urls) {
  for (final url in urls) {
    if (url == null || url.isEmpty) continue;
    final u = url.trim();
    if (!u.startsWith('http')) continue;
    precacheImage(NetworkImage(u), context);
  }
}
