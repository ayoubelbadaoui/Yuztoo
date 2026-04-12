part of 'news_section.dart';

extension _NewsSectionUi on _NewsSectionState {
  Widget _portraitImageTile(String imageUrl) {
    return ClipRRect(
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
  }

  Widget _buildPairedPortraitGallery(double maxWidth) {
    final hasMultiplePages = _pageCount > 1;
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
            itemCount: _pageCount,
            clipBehavior: Clip.hardEdge,
            onPageChanged: _onGalleryPageChanged,
            itemBuilder: (context, pageIndex) {
              final i0 = pageIndex * 2;
              final i1 = i0 + 1;
              final urls = widget.imageUrls;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: tileW,
                    height: tileH,
                    child: _portraitImageTile(urls[i0]),
                  ),
                  const SizedBox(width: _NewsSectionState._pairGap),
                  SizedBox(
                    width: tileW,
                    height: tileH,
                    child: i1 < urls.length
                        ? _portraitImageTile(urls[i1])
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
          child: _pageCount > 1
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pageCount,
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
