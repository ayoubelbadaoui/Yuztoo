part of 'yuztoo_contact_edit_screen.dart';

extension _YuztooContactEditScreenUi on _YuztooContactEditScreenState {
  Widget _buildEditUi(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            YuztooTabHeader(
              title: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: YBackButton(
                      onPressed: () {
                        if (!_saving) Navigator.of(context).maybePop();
                      },
                    ),
                  ),
                  Flexible(
                    child: YuztooTabHeader.gradientTitle('Modifier le profil'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _saving ? null : () => _save(context),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: MerchantColors.gold,
                          ),
                        )
                      : Text(
                          'Enregistrer',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: MerchantColors.gold,
                          ),
                        ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 32 + bottomInset),
                children: [
                  Center(child: _buildPhotoPicker()),
                  const SizedBox(height: 24),
                  _field(
                    label: 'Nom',
                    controller: _nameCtrl,
                    hint: 'Pascal',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    label: 'Titre',
                    controller: _titleCtrl,
                    hint: 'Fondateur de Yuztoo',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    label: 'Message',
                    controller: _bioCtrl,
                    hint: 'Votre message d\'accueil…',
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Coordonnées',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MerchantColors.gold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    label: 'Téléphone',
                    controller: _phoneCtrl,
                    hint: '+33…',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    label: 'E-mail',
                    controller: _emailCtrl,
                    hint: 'contact@yuztoo.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    label: 'Adresse',
                    controller: _addressCtrl,
                    hint: 'Adresse complète',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    label: 'Site web',
                    controller: _websiteCtrl,
                    hint: 'www.yuztoo.com',
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    final url = _photoUrl;
    return Column(
      children: [
        GestureDetector(
          onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: MerchantColors.gold,
                ),
                child: ClipOval(
                  child: ColoredBox(
                    color: MerchantColors.bgHeader,
                    child: _uploadingPhoto
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: MerchantColors.gold,
                              strokeWidth: 2,
                            ),
                          )
                        : url == null || url.isEmpty
                            ? const Center(child: AppLogo(size: 56))
                            : Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Center(child: AppLogo(size: 56)),
                              ),
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: MerchantColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: MerchantColors.bgMain, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: MerchantColors.bgHeader,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Changer la photo',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: MerchantColors.gold,
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: MerchantColors.textGrey,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: MerchantColors.textWhite,
          ),
          cursorColor: MerchantColors.gold,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: MerchantColors.textGrey),
            filled: true,
            fillColor: MerchantColors.navyCard,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: MerchantColors.gold),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: MerchantColors.navyCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: MerchantColors.gold),
              title: Text('Galerie',
                  style: GoogleFonts.outfit(color: MerchantColors.textWhite)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_camera_outlined, color: MerchantColors.gold),
              title: Text('Appareil photo',
                  style: GoogleFonts.outfit(color: MerchantColors.textWhite)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    final result = await ref.read(uploadLogoProvider).call(
          filePath: picked.path,
          merchantId: widget.initial.merchantId,
        );
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);

    result.fold(
      (f) => _showError(f.message),
      (url) => setState(() => _photoUrl = url),
    );
  }

  Future<void> _save(BuildContext context) async {
    final email = _emailCtrl.text.trim();
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('Le nom est requis.');
      return;
    }
    if (email.isEmpty || !EmailValidator.isValid(email)) {
      _showError('Adresse e-mail invalide.');
      return;
    }

    setState(() => _saving = true);
    final profile = widget.initial.copyWith(
      personName: _nameCtrl.text,
      roleTitle: _titleCtrl.text,
      bio: _bioCtrl.text,
      phone: _phoneCtrl.text,
      email: email,
      address: _addressCtrl.text,
      website: _websiteCtrl.text,
      photoUrl: _photoUrl,
    );
    final result =
        await ref.read(restonsProchesRepositoryProvider).saveProfile(profile);
    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (f) => _showError(f.message),
      (_) {
        ref.invalidate(yuztooContactProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profil mis à jour',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            backgroundColor: MerchantColors.gold,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).maybePop();
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: MerchantColors.bgHeader,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
