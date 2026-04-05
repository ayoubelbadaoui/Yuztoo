import 'dart:io';

import 'package:flutter/material.dart';
import 'storefront_colors.dart';

part 'banner_section.part.dart';

/// Banner section with landscape image and profile picture overlay
class BannerSection extends StatelessWidget {
  const BannerSection({
    super.key,
    required this.bannerImageUrl,
    required this.profileImageUrl,
    this.onBannerEdit,
    this.onProfileEdit,
  });

  final String bannerImageUrl;
  final String profileImageUrl;
  final VoidCallback? onBannerEdit;
  final VoidCallback? onProfileEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Stack(
        clipBehavior: Clip.none, // Allow overflow for profile picture
        children: [
          // Banner image
          Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBannerImage(),
                // Edit button overlay for banner
                if (onBannerEdit != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildEditButton(
                      onTap: onBannerEdit!,
                      icon: Icons.camera_alt,
                      label: 'Modifier la couverture',
                    ),
                  ),
              ],
            ),
          ),
          // Profile picture overlay - positioned to overlap banner bottom
          Positioned(
            left: 24,
            bottom: -48,
            child: _buildProfilePicture(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    return _ProfilePictureTapWidget(
      onTap: onProfileEdit,
      child: Container(
        width: 96, // Total width including all padding
        height: 96, // Total height including all padding
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: GoldGradient.colors,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: _buildProfileImage(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerImage() {
    final url = bannerImageUrl.trim();
    if (url.isEmpty) {
      return _bannerPlaceholder();
    }
    if (url.startsWith('file://')) {
      return Image.file(
        File(url.substring(7)),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _bannerPlaceholder(),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _bannerPlaceholder(),
    );
  }

  Widget _buildProfileImage() {
    final url = profileImageUrl.trim();
    if (url.isEmpty) {
      return _profilePlaceholder();
    }
    if (url.startsWith('file://')) {
      return Image.file(
        File(url.substring(7)),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _profilePlaceholder(),
      );
    }
    return Image.network(
      url,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _profilePlaceholder(),
    );
  }

  Widget _bannerPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.storefront_outlined,
        size: 48,
        color: StorefrontColors.navyDark.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _profilePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: Icon(
        Icons.store_mall_directory_outlined,
        size: 40,
        color: StorefrontColors.navyDark.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildEditButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: StorefrontColors.navyDark.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
