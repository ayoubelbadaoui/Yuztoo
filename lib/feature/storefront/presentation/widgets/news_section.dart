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
    this.isUploading = false,
    this.onUploadImage,
    this.showMedia = true,
    this.showDescription = true,
    this.showUploadButton = true,
    this.onSettings,
    this.contentPlaceholder,
  });

  final String? content;
  final List<String> imageUrls;
  /// Shown when [content] is null; falls back to merchant default copy if also null.
  final String? contentPlaceholder;
  final bool isUploading;
  final VoidCallback? onUploadImage;
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

  int get _pageCount {
    final n = widget.imageUrls.length;
    if (n == 0) return 0;
    return (n + 1) ~/ 2;
  }

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showMedia) ...[
            if (widget.imageUrls.isEmpty)
              _buildEmptyMediaPlaceholder()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  return _buildPairedPortraitGallery(constraints.maxWidth);
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
