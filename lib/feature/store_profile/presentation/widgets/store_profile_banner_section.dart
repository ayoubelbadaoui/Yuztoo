import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../feature/storefront/presentation/widgets/storefront_colors.dart';

/// Read-only banner + profile picture section matching the merchant Vitrine layout.
/// Same dimensions and styling as [BannerSection] but without edit buttons.
class StoreProfileBannerSection extends StatelessWidget {
  const StoreProfileBannerSection({
    super.key,
    this.bannerImageUrl,
    this.profileImageUrl,
  });

  final String? bannerImageUrl;
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner image - same height as Vitrine (180)
          Container(
            height: 180,
            width: double.infinity,
            child: _buildBannerImage(),
          ),
          // Profile picture overlay - same position as Vitrine (left 24, bottom -48)
          Positioned(
            left: 24,
            bottom: -48,
            child: _buildProfilePicture(),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerImage() {
    final url = bannerImageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _placeholderBanner();
    }
    if (url.startsWith('file://')) {
      final path = url.substring(7);
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderBanner(),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholderBanner(),
    );
  }

  Widget _placeholderBanner() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: StorefrontColors.navyDark.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Container(
      width: 96,
      height: 96,
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
    );
  }

  Widget _buildProfileImage() {
    final url = profileImageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _placeholderProfile();
    }
    if (url.startsWith('file://')) {
      final path = url.substring(7);
      return Image.file(
        File(path),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderProfile(),
      );
    }
    return Image.network(
      url,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholderProfile(),
    );
  }

  Widget _placeholderProfile() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: Icon(
        Icons.store,
        size: 40,
        color: StorefrontColors.navyDark.withValues(alpha: 0.5),
      ),
    );
  }
}
