import 'package:flutter/material.dart';
import 'storefront_colors.dart';

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
                Image.network(
                  bannerImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.image, size: 48, color: StorefrontColors.navyDark.withValues(alpha: 0.3)),
                    );
                  },
                ),
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
                    child: Icon(Icons.person, size: 40, color: StorefrontColors.navyDark.withValues(alpha: 0.5)),
                  );
                },
              ),
            ),
          ),
        ),
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

class _ProfilePictureTapWidget extends StatefulWidget {
  const _ProfilePictureTapWidget({
    required this.onTap,
    required this.child,
  });

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_ProfilePictureTapWidget> createState() => _ProfilePictureTapWidgetState();
}

class _ProfilePictureTapWidgetState extends State<_ProfilePictureTapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 96,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Opacity(
                opacity: _isPressed ? 0.8 : 1.0,
                child: widget.child,
              ),
            ),
            // Subtle overlay when pressed to show it's interactive
            if (_isPressed)
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

