import 'package:flutter/material.dart';
import 'storefront_colors.dart';

/// Banner section with landscape image and profile picture overlay
class BannerSection extends StatelessWidget {
  const BannerSection({
    super.key,
    required this.bannerImageUrl,
    required this.profileImageUrl,
  });

  final String bannerImageUrl;
  final String profileImageUrl;

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
            child: Image.network(
              bannerImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 48, color: Colors.grey),
                );
              },
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
    return Container(
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
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
            child: Image.network(
              profileImageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 40),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

