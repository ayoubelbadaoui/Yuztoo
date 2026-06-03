part of 'news_section.dart';

extension _NewsSectionUi on _NewsSectionState {
  /// One thumbnail in the actualité gallery.
  ///
  /// Tapping the tile opens a full-screen, pinch-to-zoom, swipe-between
  /// gallery viewer (see [_openFullscreenViewer]) — the user feedback was
  /// "dans actualité les clients doivent pouvoir agrandir les vignettes
  /// en cliquant dessus". The merchant's red X delete overlay sits on top
  /// of the tile in the Stack, so its hit region wins over the underlying
  /// tap handler — tapping the X still triggers the delete confirmation,
  /// tapping anywhere else on the tile opens the viewer.
  Widget _portraitImageTile(String imageUrl, {VoidCallback? onTap}) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[100],
            alignment: Alignment.center,
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: StorefrontColors.primaryGold.withValues(alpha: 0.85),
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[100],
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            color: StorefrontColors.textSecondary,
            size: 28,
          ),
        ),
      ),
    );

    final tappable = onTap == null
        ? image
        : GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: image,
          );

    if (widget.onDeleteImage == null) return tappable;

    return Stack(
      children: [
        tappable,
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _confirmDelete(imageUrl),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// Pushes a full-screen image viewer on top of the storefront. Uses a
  /// fade transition so the tap feels like an "expand" rather than a
  /// route change.
  void _openFullscreenViewer(List<String> urls, int initialIndex) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: _FullscreenGalleryViewer(
            imageUrls: urls,
            initialIndex: initialIndex,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String imageUrl) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StorefrontColors.creamLight,
        title: const Text('Supprimer cette photo ?'),
        content: const Text(
            'Cette action est irréversible. La photo sera définitivement supprimée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Supprimer',
              style: TextStyle(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) widget.onDeleteImage?.call(imageUrl);
    });
  }

  Widget _buildPairedPortraitGallery(double maxWidth, List<String> urls) {
    final pageCount = urls.isEmpty ? 0 : (urls.length + 1) ~/ 2;
    final hasMultiplePages = pageCount > 1;
    // Single page: two images use full row. Multiple pages: reserve a cream strip
    // after each pair so the next slide starts after visible breathing room.
    final trailing =
        hasMultiplePages ? _NewsSectionState._interSlideGap : 0.0;
    final tileW =
        (maxWidth - _NewsSectionState._pairGap - trailing) / 2;
    final tileH = tileW / _NewsSectionState._portraitAspect;

    return Column(
      children: [
        SizedBox(
          height: tileH,
          child: PageView.builder(
            controller: _pageController,
            itemCount: pageCount,
            clipBehavior: Clip.hardEdge,
            onPageChanged: _onGalleryPageChanged,
            itemBuilder: (context, pageIndex) {
              final i0 = pageIndex * 2;
              final i1 = i0 + 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: tileW,
                    height: tileH,
                    child: _portraitImageTile(
                      urls[i0],
                      onTap: () => _openFullscreenViewer(urls, i0),
                    ),
                  ),
                  const SizedBox(width: _NewsSectionState._pairGap),
                  SizedBox(
                    width: tileW,
                    height: tileH,
                    child: i1 < urls.length
                        ? _portraitImageTile(
                            urls[i1],
                            onTap: () => _openFullscreenViewer(urls, i1),
                          )
                        : _emptyPortraitSlot(),
                  ),
                  if (hasMultiplePages)
                    SizedBox(
                      width: _NewsSectionState._interSlideGap,
                      height: tileH,
                      child: const ColoredBox(
                        color: StorefrontColors.creamLight,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        // Fixed strip so adding a 3rd image (2nd page + dots) does not shift content above.
        SizedBox(
          height: 22,
          child: pageCount > 1
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pageCount,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == index ? 14 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? StorefrontColors.primaryGold
                            : StorefrontColors.primaryGold.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _emptyPortraitSlot() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StorefrontColors.creamLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StorefrontColors.primaryGold.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  Widget _buildEmptyMediaPlaceholder() {
    // Client view (read-only): show a friendly message, no upload hints.
    if (!widget.showUploadButton) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: StorefrontColors.creamLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: StorefrontColors.primaryGold.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 36,
              color: StorefrontColors.primaryGold.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Retrouvez ici les actualités de ce commerce',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: StorefrontColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // Merchant view: show upload-hint slots.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final tileW = (maxW - _NewsSectionState._pairGap) / 2;
        final tileH = tileW / _NewsSectionState._portraitAspect;
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: tileW,
                  height: tileH,
                  child: _emptySlotWithHint(showIcon: true),
                ),
                const SizedBox(width: _NewsSectionState._pairGap),
                SizedBox(
                  width: tileW,
                  height: tileH,
                  child: _emptySlotWithHint(showIcon: false),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Photos de votre actualité',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: StorefrontColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajoutez des images ci-dessous — affichage en deux colonnes, format portrait.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: StorefrontColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _emptySlotWithHint({required bool showIcon}) {
    return Container(
      decoration: BoxDecoration(
        color: StorefrontColors.creamLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StorefrontColors.primaryGold.withValues(alpha: 0.22),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: showIcon
          ? Icon(
              Icons.add_photo_alternate_outlined,
              size: 36,
              color: StorefrontColors.primaryGold.withValues(alpha: 0.5),
            )
          : null,
    );
  }
}

class _UploadContentButton extends StatelessWidget {
  const _UploadContentButton({
    this.isUploading = false,
    this.onTap,
  });

  final bool isUploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUploading ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: StorefrontColors.primaryGold.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: StorefrontColors.primaryGold.withValues(alpha: 0.2),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: GoldGradient.colors,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: StorefrontColors.primaryGold,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Charger un contenu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: StorefrontColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUploading ? 'TÉLÉVERSEMENT...' : 'PHOTO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: StorefrontColors.primaryGold.withValues(alpha: 0.7),
                        letterSpacing: 1.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Fullscreen gallery viewer ─────────────────────────────────────────────
//
// Tapping a thumbnail in the news/actualité gallery pushes this viewer over
// the storefront. It exposes:
//
//   * pinch-to-zoom + pan via [InteractiveViewer] (1× → 4×),
//   * horizontal swipe between images via [PageView] (when more than one),
//   * close button + page counter overlays on a black backdrop,
//   * BoxFit.contain so portrait shots are never cropped.
//
// Lives next to [NewsSection] because it is tightly coupled to the gallery
// layout above it; promoting to a shared widget can come later if other
// surfaces (promos, banners) need the same affordance.

class _FullscreenGalleryViewer extends StatefulWidget {
  const _FullscreenGalleryViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_FullscreenGalleryViewer> createState() =>
      _FullscreenGalleryViewerState();
}

class _FullscreenGalleryViewerState extends State<_FullscreenGalleryViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    final hasMultiple = urls.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: urls.length,
              physics: hasMultiple
                  ? const PageScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      urls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: StorefrontColors.primaryGold,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.4),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Fermer',
                ),
              ),
            ),
            if (hasMultiple)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${urls.length}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
