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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileAvatarCircle(
            imageFile: _profileImageFile,
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
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (city.isNotEmpty) _ProfileAvatarInfoLine(city),
                    if (phone.isNotEmpty) _ProfileAvatarInfoLine('Tel: $phone'),
                    if (email.isNotEmpty) _ProfileAvatarInfoLine(email),
                    if (name == 'Utilisateur' &&
                        email.isEmpty &&
                        phone.isEmpty &&
                        city.isEmpty)
                      _ProfileAvatarInfoLine(
                        'Chargement...',
                        style: TextStyle(
                          color: MerchantColors.textGrey.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                );
              },
              loading: () => Column(
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
                  const SizedBox(height: 4),
                  _ProfileAvatarInfoLine(
                    'Chargement des données...',
                    style: TextStyle(
                      color: MerchantColors.textGrey.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              error: (error, stack) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Utilisateur',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ProfileAvatarInfoLine(
                    'Impossible de charger les données',
                    style: TextStyle(
                      color: Colors.red.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileAvatarCircle(
            imageFile: _profileImageFile,
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
  });

  final File? imageFile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MerchantColors.navyCard,
          border: Border.all(color: MerchantColors.gold, width: 3),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageFile != null)
              ClipOval(
                child: Image.file(
                  imageFile!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.person,
                        color: MerchantColors.gold,
                        size: 48,
                      ),
                    );
                  },
                ),
              )
            else
              const Center(
                child: Icon(
                  Icons.person,
                  color: MerchantColors.gold,
                  size: 48,
                ),
              ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.3),
              ),
              child: const Center(
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatarInfoLine extends StatelessWidget {
  const _ProfileAvatarInfoLine(this.text, {this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        style: style ??
            GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textGrey,
              height: 1.5,
            ),
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
