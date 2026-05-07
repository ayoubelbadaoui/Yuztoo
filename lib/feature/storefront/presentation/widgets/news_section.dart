import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'storefront_colors.dart';

part 'news_section.part.dart';

/// News / Actualité — images of content, description, and upload.
class NewsSection extends StatefulWidget {
  const NewsSection({
    super.key,
    this.content,
    this.imageUrls = const [],
    this.pendingDeleteUrls = const {},
    this.isUploading = false,
    this.isClearingAll = false,
    this.onUploadImage,
    this.onDeleteImage,
    this.onClearAll,
    this.showMedia = true,
    this.showDescription = true,
    this.showUploadButton = true,
    this.onSettings,
    this.contentPlaceholder,
  });

  final String? content;
  final List<String> imageUrls;
  /// URLs whose deletion is in-flight; filtered out immediately for optimistic UI.
  final Set<String> pendingDeleteUrls;
  /// Shown when [content] is null; falls back to merchant default copy if also null.
  final String? contentPlaceholder;
  final bool isUploading;
  /// True while a "clear all" wipe is in progress.
  final bool isClearingAll;
  final VoidCallback? onUploadImage;
  /// Called with the image URL when the merchant taps the delete overlay on a tile.
  final ValueChanged<String>? onDeleteImage;
  /// Called when the merchant taps "Tout supprimer" to wipe the gallery.
  final VoidCallback? onClearAll;
  final bool showMedia;

  /// Whether to show the description text card below the gallery.
  /// Set to false on the client Actualité tab (photos only).
  final bool showDescription;
  final bool showUploadButton;
  final VoidCallback? onSettings;

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  /// Space between the two portrait images on one row.
  static const double _pairGap = 12;

  /// Extra width after each pair when there is another page — real scroll gap so
  /// slides do not look stuck together (viewportFraction cannot do this alone).
  static const double _interSlideGap = 14;

  late final PageController _pageController = PageController();

  int _currentPage = 0;

  /// Portrait tiles: width : height = 3 : 4 (vertical, not wide landscape).
  static const double _portraitAspect = 3 / 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onGalleryPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    // Filter out in-flight deletes for instant optimistic feedback.
    final effectiveUrls = widget.pendingDeleteUrls.isEmpty
        ? widget.imageUrls
        : widget.imageUrls
            .where((u) => !widget.pendingDeleteUrls.contains(u))
            .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showMedia) ...[
            // "Clear all" row — only shown to merchants when images exist.
            if (widget.onClearAll != null && effectiveUrls.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: widget.isClearingAll ? null : widget.onClearAll,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    icon: widget.isClearingAll
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red.shade400,
                            ),
                          )
                        : Icon(Icons.delete_sweep_outlined,
                            size: 18, color: Colors.red.shade600),
                    label: Text(
                      widget.isClearingAll ? 'Suppression…' : 'Tout effacer',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (widget.isClearingAll || effectiveUrls.isEmpty)
              _buildEmptyMediaPlaceholder()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  return _buildPairedPortraitGallery(
                      constraints.maxWidth, effectiveUrls);
                },
              ),
            const SizedBox(height: 20),
          ],
          if (widget.showDescription)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.grey[100]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.content ??
                        widget.contentPlaceholder ??
                        'Présentez vos actualités en quelques lignes pour informer vos clients en temps réel.',
                    style: const TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: StorefrontColors.textSecondary,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onSettings != null) ...[
                  const SizedBox(width: 16),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onSettings,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.settings_suggest_outlined,
                          size: 22,
                          color: StorefrontColors.primaryGold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.showUploadButton) ...[
            const SizedBox(height: 20),
            _UploadContentButton(
              isUploading: widget.isUploading,
              onTap: widget.onUploadImage,
            ),
          ],
        ],
      ),
    );
  }
}
