part of 'personal_information_screen.dart';

extension _PersonalInformationUi on _PersonalInformationScreenState {
  // ── Photo picker ──────────────────────────────────────────────────────────

  Future<void> _pickAndUploadPhoto(String uid) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: MerchantColors.bgMain,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _buildPickerSheet(ctx),
    );
    if (source == null || !mounted) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final croppedPath = await cropImage(
        picked.path,
        ratioX: 1,
        ratioY: 1,
        circleShape: true,
      );
      if (croppedPath == null || !mounted) return;

      _setPhotoUploading(true);

      final result = await ref
          .read(uploadClientAvatarProvider)
          .call(filePath: croppedPath, uid: uid);

      if (!mounted) return;

      result.fold(
        (failure) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur lors de l\'envoi de la photo',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        (downloadUrl) async {
          await ref
              .read(updateAuthUserProfileProvider)
              .call(photoUrl: downloadUrl);
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Une erreur est survenue',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) _setPhotoUploading(false);
    }
  }

  Widget _buildPickerSheet(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: MerchantColors.gold.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Choisir une photo',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MerchantColors.textWhite,
              ),
            ),
            const SizedBox(height: 16),
            _buildPickerOption(
              context,
              icon: Icons.camera_alt_outlined,
              label: 'Prendre une photo',
              source: ImageSource.camera,
            ),
            Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: MerchantColors.gold.withValues(alpha: 0.15),
            ),
            _buildPickerOption(
              context,
              icon: Icons.photo_library_outlined,
              label: 'Choisir depuis la galerie',
              source: ImageSource.gallery,
            ),
            const SizedBox(height: 8),
            Divider(
              height: 1,
              color: MerchantColors.gold.withValues(alpha: 0.1),
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded, color: Colors.redAccent),
              title: Text(
                'Annuler',
                style: GoogleFonts.outfit(color: Colors.redAccent),
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ImageSource source,
  }) {
    return ListTile(
      leading: Icon(icon, color: MerchantColors.gold),
      title: Text(
        label,
        style: GoogleFonts.outfit(
          color: MerchantColors.textWhite,
          fontSize: 14,
        ),
      ),
      onTap: () => Navigator.of(context).pop(source),
    );
  }

  // ── Scaffold ──────────────────────────────────────────────────────────────

  Widget _buildScaffold(
    BuildContext context, {
    required String? uid,
    required String fullName,
    required String email,
    required String phone,
    required String city,
    required int completionPercent,
    bool hasPhoto = false,
    bool hasDob = false,
    String? photoUrl,
    bool photoUploading = false,
    VoidCallback? onPhotoTap,
    VoidCallback? onCreateProAccount,
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MerchantColors.bgHeader,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(context, uid: uid),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_editing)
                      _buildEditForm(context, uid: uid)
                    else ...[
                      _buildIdentityCard(
                        fullName,
                        email,
                        phone,
                        photoUrl: photoUrl,
                        isUploading: photoUploading,
                        onPhotoTap: onPhotoTap,
                      ),
                      // Prominent CTA in addition to the pencil icon in the
                      // header — earlier feedback flagged the profile as
                      // "no longer editable", which we traced to the small
                      // pencil being easy to miss on smaller phones. The
                      // text button is unambiguous; the pencil stays for
                      // power-users.
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _startEdit,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          height: 46,
                          decoration: BoxDecoration(
                            color: MerchantColors.bgHeader,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: MerchantColors.gold,
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.edit_outlined,
                                  color: MerchantColors.gold,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Modifier mes informations',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: MerchantColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Villes connectées',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MerchantColors.textWhite,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _CitiesWidget(),
                    const SizedBox(height: 24),
                    _buildYuztooCard(fullName),
                    const SizedBox(height: 16),
                    _buildCompletionBar(
                      completionPercent,
                      hasPhoto,
                      hasDob,
                      onPhotoTap: onPhotoTap,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: onCreateProAccount,
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD4AF37), Color(0xFFD4A017)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: MerchantColors.gold.withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: -2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Créer un compte pro',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: MerchantColors.bgHeader,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required String? uid}) {
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderStronger),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _editing
                    ? _cancelEdit
                    : () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: MerchantColors.gold, width: 1.5),
                  ),
                  child: Center(
                    child: Icon(
                      _editing
                          ? Icons.close_rounded
                          : Icons.arrow_back_ios_new_rounded,
                      color: MerchantColors.gold,
                      size: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Informations personnelles',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.textWhite,
                  ),
                ),
              ),
              if (!_editing)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _startEdit,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: MerchantColors.gold, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.edit_outlined,
                        color: MerchantColors.gold,
                        size: 16,
                      ),
                    ),
                  ),
                )
              else if (uid != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _saving ? null : () => _save(uid),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFD4A017)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: MerchantColors.bgHeader,
                            ),
                          )
                        : Text(
                            'Enregistrer',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: MerchantColors.bgHeader,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm(BuildContext context, {required String? uid}) {
    const inputDeco = InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF0B2540),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0x33D4A017)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0x33D4A017)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: MerchantColors.gold, width: 1.5),
      ),
      labelStyle: TextStyle(color: MerchantColors.textGrey),
      hintStyle: TextStyle(color: MerchantColors.textGrey),
    );

    final dobLabel = _selectedDob != null
        ? '${_selectedDob!.day.toString().padLeft(2, '0')}/'
            '${_selectedDob!.month.toString().padLeft(2, '0')}/'
            '${_selectedDob!.year}'
        : 'Sélectionner';

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: inputDeco,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Prénom'),
          const SizedBox(height: 6),
          TextField(
            controller: _firstNameCtrl,
            style: GoogleFonts.outfit(
                color: MerchantColors.textWhite, fontSize: 15),
            decoration: const InputDecoration(hintText: 'Votre prénom'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          _sectionLabel('Nom'),
          const SizedBox(height: 6),
          TextField(
            controller: _lastNameCtrl,
            style: GoogleFonts.outfit(
                color: MerchantColors.textWhite, fontSize: 15),
            decoration: const InputDecoration(hintText: 'Votre nom'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          _sectionLabel('Date de naissance'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDob,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF0B2540),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dobLabel,
                      style: GoogleFonts.outfit(
                        color: _selectedDob != null
                            ? MerchantColors.textWhite
                            : MerchantColors.textGrey,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined,
                      color: MerchantColors.gold, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: MerchantColors.textGrey,
          letterSpacing: 0.2,
        ),
      );

  Widget _buildIdentityCard(
    String name,
    String email,
    String phone, {
    String? photoUrl,
    bool isUploading = false,
    VoidCallback? onPhotoTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MerchantColors.bgHeader,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: isUploading ? null : onPhotoTap,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Avatar circle
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MerchantColors.gold.withValues(alpha: 0.15),
                    border: onPhotoTap != null
                        ? Border.all(
                            color: MerchantColors.gold.withValues(alpha: 0.5),
                            width: 1.5,
                          )
                        : null,
                    image: photoUrl != null && photoUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: isUploading
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: MerchantColors.gold,
                          ),
                        )
                      : (photoUrl == null || photoUrl.isEmpty)
                          ? Text(
                              avatarInitial(name),
                              style: GoogleFonts.outfit(
                                color: MerchantColors.textWhite,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                ),
                // Camera badge
                if (onPhotoTap != null && !isUploading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: MerchantColors.gold,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: MerchantColors.bgHeader,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: MerchantColors.bgHeader,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: MerchantColors.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tél : $phone',
                  style: GoogleFonts.outfit(
                    color: MerchantColors.textLightGrey,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.outfit(
                    color: MerchantColors.textLightGrey,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYuztooCard(String fullName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2540), Color(0xFF0E2A44)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFF5F5F5), Color(0xFFD4A017)],
                ).createShader(bounds),
                child: Text(
                  'yuztoo',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MerchantColors.gold.withValues(alpha: 0.15),
                  border: Border.all(
                    color: MerchantColors.gold.withValues(alpha: 0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    avatarInitial(fullName.isNotEmpty ? fullName : 'U'),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.gold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            fullName.isNotEmpty ? fullName : 'Client Yuztoo',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MerchantColors.textWhite,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Carte Fidélité · Membre',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBar(
    int completionPercent,
    bool hasPhoto,
    bool hasDob, {
    VoidCallback? onPhotoTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Profil complété à',
              style: GoogleFonts.outfit(
                color: MerchantColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: completionPercent == 100
                    ? MerchantColors.gold
                    : MerchantColors.bgHeader,
                borderRadius: BorderRadius.circular(14),
                border: completionPercent < 100
                    ? Border.all(
                        color: MerchantColors.gold.withValues(alpha: 0.5))
                    : null,
              ),
              child: Text(
                '$completionPercent%',
                style: GoogleFonts.outfit(
                  color: completionPercent == 100
                      ? MerchantColors.bgHeader
                      : MerchantColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: completionPercent / 100.0,
            minHeight: 6,
            backgroundColor: MerchantColors.gold.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(
              completionPercent == 100
                  ? MerchantColors.gold
                  : MerchantColors.gold.withValues(alpha: 0.7),
            ),
          ),
        ),
        if (!hasDob) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _startEdit,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  Icons.cake_outlined,
                  size: 13,
                  color: MerchantColors.gold.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ajoute ta date de naissance pour recevoir des surprises le jour J 🎂',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.textGrey,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: MerchantColors.gold.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ],
        if (!hasPhoto) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onPhotoTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  size: 13,
                  color: MerchantColors.gold.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ajoute une photo de profil pour compléter à 100\u202f%',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.textGrey,
                    ),
                  ),
                ),
                if (onPhotoTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: MerchantColors.gold.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CitiesWidget extends ConsumerStatefulWidget {
  const _CitiesWidget();

  @override
  ConsumerState<_CitiesWidget> createState() => _CitiesWidgetState();
}

class _CitiesWidgetState extends ConsumerState<_CitiesWidget> {
  void _openAddCityPicker(
      BuildContext context, String uid, List<String> current) {
    final available = frenchCities
        .where((c) => !current.any((x) => x.toLowerCase() == c.toLowerCase()))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MerchantColors.navyCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // `filtered` lives in the outer closure so that StatefulBuilder
        // reads the updated reference on each setState call.
        var filtered = available;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (ctx, setSheetState) {
                return Column(
                  children: [
                    // ── Drag handle ─────────────────────────────────────────
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 4),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: MerchantColors.gold.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Text(
                        'Ajouter une ville connectée',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // ── Search field ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        autofocus: true,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Rechercher une ville...',
                          hintStyle: GoogleFonts.outfit(
                            color: MerchantColors.textGrey,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: MerchantColors.textGrey,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: MerchantColors.bgHeader,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (query) {
                          setSheetState(() {
                            filtered = query.trim().isEmpty
                                ? available
                                : available
                                    .where((c) => c
                                        .toLowerCase()
                                        .contains(query.toLowerCase().trim()))
                                    .toList();
                          });
                        },
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: MerchantColors.gold.withValues(alpha: 0.15),
                    ),
                    // ── City list ─────────────────────────────────────────────
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Aucune ville trouvée',
                          style: GoogleFonts.outfit(
                            color: MerchantColors.textGrey,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            thickness: 1,
                            indent: 20,
                            endIndent: 20,
                            color:
                                MerchantColors.gold.withValues(alpha: 0.08),
                          ),
                          itemBuilder: (_, i) {
                            final city = filtered[i];
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                Navigator.of(ctx).pop();
                                final newList = [...current, city];
                                final result = await ref
                                    .read(setConnectedCitiesProvider)
                                    .call(uid: uid, cities: newList);
                                if (!context.mounted) return;
                                result.fold(
                                  (f) => ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(content: Text(f.message)),
                                  ),
                                  (_) => ref
                                      .invalidate(connectedCitiesProvider(uid)),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: MerchantColors.gold
                                          .withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      city,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: MerchantColors.textWhite,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.add_circle_outline_rounded,
                                      size: 18,
                                      color: MerchantColors.gold
                                          .withValues(alpha: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _removeCity(
      String uid, String cityName, List<String> current) async {
    if (current.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vous devez avoir au moins une ville.')),
      );
      return;
    }
    final updated = current.where((c) => c != cityName).toList();
    final result = await ref
        .read(setConnectedCitiesProvider)
        .call(uid: uid, cities: updated);
    if (!context.mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) => ref.invalidate(connectedCitiesProvider(uid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    if (authState is! Authenticated) return const SizedBox.shrink();

    final uid = authState.user.id;
    final cities = ref.watch(connectedCitiesProvider(uid)).value ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...cities.map((name) => _buildPill(name, uid, cities)),
        GestureDetector(
          onTap: () => _openAddCityPicker(context, uid, cities),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MerchantColors.gold, width: 2),
            ),
            child: const Icon(Icons.add_rounded,
                color: MerchantColors.gold, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildPill(String name, String uid, List<String> current) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 4, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: MerchantColors.gold,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MerchantColors.bgHeader,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeCity(uid, name, current),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: MerchantColors.bgHeader.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: MerchantColors.bgHeader, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}
