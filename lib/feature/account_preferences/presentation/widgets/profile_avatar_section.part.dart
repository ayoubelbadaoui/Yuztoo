part of 'profile_avatar_section.dart';

extension _ProfileAvatarSectionUi on _ProfileAvatarSectionState {
  Widget _profileAvatarBuild(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (authState is! Authenticated) {
      return _buildLoadingState();
    }

    final userId = authState.user.id;
    final storefrontAsync = ref.watch(storefrontProvider);
    final profileBasicsAsync = ref.watch(
      userProfileBasicsProvider(userId),
    );
    final personalImagePathAsync = ref.watch(
      personalProfileImagePathProvider(userId),
    );

    final imagePath = personalImagePathAsync.valueOrNull;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileImageFromCache(imagePath);
    });

    return _ProfileAvatarSectionChrome(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ProfileAvatarCircle(
            imageFile: _profileImageFile,
            photoUrl: authState.user.photoUrl,
            isUploading: _isUploading,
            onTap: () => _showImagePickerSheet(context),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: profileBasicsAsync.when(
              data: (profileBasics) {
                final name = authState.user.displayName ?? 'Utilisateur';
                final email = profileBasics?.email ??
                    authState.user.email ??
                    '';
                final phone = profileBasics?.phone ??
                    authState.user.phoneNumber ??
                    '';
                final city = resolveCityForProfile(
                  profileBasics,
                  isMerchant: authState.user.isMerchant,
                  storefront: storefrontAsync.valueOrNull,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onEditProfile,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_outlined,
                              color: MerchantColors.gold, size: 15),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (city.isNotEmpty) _ProfileAvatarInfoLine(city),
                    if (phone.isNotEmpty)
                      _ProfileAvatarInfoLine(phone,
                          icon: Icons.phone_outlined),
                    if (email.isNotEmpty)
                      _ProfileAvatarInfoLine(email,
                          icon: Icons.mail_outline_rounded),
                  ],
                );
              },
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chargement...',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              error: (_, __) => Text(
                'Utilisateur',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return _ProfileAvatarSectionChrome(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ProfileAvatarCircle(
            imageFile: _profileImageFile,
            isUploading: _isUploading,
            onTap: () {
              final authState = ref.read(authStateProvider);
              if (authState is Authenticated) {
                _showImagePickerSheet(context);
              }
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chargement...',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerSheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MerchantColors.bgMain,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: MerchantColors.textGrey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Changer la photo de profil',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PickerOption(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                _PickerOption(
                  icon: Icons.camera_alt,
                  label: 'Caméra',
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatarSectionChrome extends StatelessWidget {
  const _ProfileAvatarSectionChrome({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _ProfileAvatarCircle extends StatelessWidget {
  const _ProfileAvatarCircle({
    required this.imageFile,
    required this.onTap,
    this.photoUrl,
    this.isUploading = false,
  });

  final File? imageFile;
  final String? photoUrl;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imageFile != null || (photoUrl != null && photoUrl!.isNotEmpty);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 88,
        height: 88,
        child: Stack(
          children: [
            // ── avatar circle ────────────────────────────────────────────
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantColors.navyCard,
                border: Border.all(color: MerchantColors.gold, width: 2.5),
              ),
              child: ClipOval(
                child: imageFile != null
                    ? Image.file(
                        imageFile!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : (photoUrl != null && photoUrl!.isNotEmpty)
                        ? Image.network(
                            photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
              ),
            ),
            // ── bottom-right camera badge ──────────────────────────────
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MerchantColors.gold,
                  border: Border.all(color: MerchantColors.bgMain, width: 2),
                ),
                child: isUploading
                    ? const Padding(
                        padding: EdgeInsets.all(5),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MerchantColors.bgHeader,
                        ),
                      )
                    : Icon(
                        hasImage ? Icons.edit : Icons.camera_alt,
                        color: MerchantColors.bgHeader,
                        size: 13,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => const Center(
        child: Icon(Icons.person, color: MerchantColors.gold, size: 40),
      );
}

class _ProfileAvatarInfoLine extends StatelessWidget {
  const _ProfileAvatarInfoLine(this.text, {this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: MerchantColors.textGrey, size: 12),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textGrey,
                height: 1.4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Image picker option widget with merchant colors
class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 132,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: MerchantColors.navyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: MerchantColors.gold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: MerchantColors.gold,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: MerchantColors.darkOverlay,
                  size: 26,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
