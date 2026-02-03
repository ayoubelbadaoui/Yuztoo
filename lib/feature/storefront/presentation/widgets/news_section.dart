import 'package:flutter/material.dart';
import 'storefront_colors.dart';

/// News/Content section with placeholder text and settings button
class NewsSection extends StatelessWidget {
  const NewsSection({
    super.key,
    this.content,
    this.onSettings,
  });

  final String? content;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
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
                    content ??
                        'Présentez vos actualités en quelques lignes pour informer vos clients en temps réel.',
                    style: const TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: StorefrontColors.textSecondary,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSettings,
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
            ),
          ),
          const SizedBox(height: 20),
          _UploadContentButton(),
        ],
      ),
    );
  }
}

class _UploadContentButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Handle upload
        },
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
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
                    Icons.cloud_upload_outlined,
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
                      'PHOTO OU VIDÉO',
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

