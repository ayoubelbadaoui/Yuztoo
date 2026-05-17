part of 'client_onboarding_screen.dart';

extension _ClientOnboardingScreenUi on _ClientOnboardingScreenState {
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: (_currentStep > 0 && !_isSaving) ? _goBack : null,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: (_currentStep > 0 && !_isSaving)
                      ? MerchantOnboardingColors.primaryGold
                      : MerchantOnboardingColors.primaryGold
                          .withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0,
                  end: (_currentStep + 1) / _ClientOnboardingScreenState._totalSteps,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: MerchantOnboardingColors.bgDark2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      MerchantOnboardingColors.primaryGold,
                    ),
                    minHeight: 6,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return SizedBox.expand(
      key: const ValueKey('loading'),
      child: Container(
        color: MerchantColors.bgMain,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    MerchantOnboardingColors.primaryGold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Enregistrement...',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: MerchantOnboardingColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return ResponsiveScrollBody(
      horizontalPadding: 24,
      verticalPadding: 0,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantOnboardingColors.bgDark2,
              border: Border.all(
                color: MerchantOnboardingColors.primaryGold,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              size: 44,
              color: MerchantOnboardingColors.primaryGold,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Bienvenue',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Complétez votre profil en quelques étapes pour commencer à utiliser votre espace client.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              height: 1.5,
              color: MerchantOnboardingColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          _buildGoldButton(
            label: 'Commencer',
            enabled: !_isSaving,
            onTap: _goNext,
          ),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return ResponsiveScrollBody(
      horizontalPadding: 24,
      verticalPadding: 0,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantOnboardingColors.bgDark2,
              border: Border.all(
                color: MerchantOnboardingColors.primaryGold,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 40,
              color: MerchantOnboardingColors.primaryGold,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Comment vous appelez-vous ?',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildNameField(
            controller: _firstNameController,
            hintText: 'Prénom',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          _buildNameField(
            controller: _lastNameController,
            hintText: 'Nom de famille',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 32),
          _buildGoldButton(
            label: 'Suivant',
            enabled: _canProceedName && !_isSaving,
            onTap: _goNext,
          ),
        ],
      ),
    );
  }

  Widget _buildNameField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      style: GoogleFonts.outfit(
        fontSize: 16,
        color: MerchantOnboardingColors.textLight,
      ),
      cursorColor: MerchantOnboardingColors.primaryGold,
      decoration: InputDecoration(
        prefixIcon: Icon(icon,
            color: MerchantOnboardingColors.textGrey, size: 20),
        hintText: hintText,
        hintStyle: GoogleFonts.outfit(
          color: MerchantOnboardingColors.textGrey,
        ),
        filled: true,
        fillColor: MerchantOnboardingColors.bgDark2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MerchantOnboardingColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MerchantOnboardingColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: MerchantOnboardingColors.primaryGold,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildGoldButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? const [Color(0xFFD4AF37), Color(0xFFD4A017)]
                : [
                    const Color(0xFFD4AF37).withValues(alpha: 0.3),
                    const Color(0xFFD4A017).withValues(alpha: 0.3),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: enabled
                  ? const Color(0xFF0E2A44)
                  : const Color(0xFF0E2A44).withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDobStep() {
    final hasDob = _selectedDob != null;
    final dobText = hasDob
        ? '${_selectedDob!.day.toString().padLeft(2, '0')}/'
            '${_selectedDob!.month.toString().padLeft(2, '0')}/'
            '${_selectedDob!.year}'
        : 'Sélectionner ma date de naissance';

    return ResponsiveScrollBody(
      horizontalPadding: 24,
      verticalPadding: 0,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantOnboardingColors.bgDark2,
              border: Border.all(
                color: MerchantOnboardingColors.primaryGold,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.cake_outlined,
              size: 40,
              color: MerchantOnboardingColors.primaryGold,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Date de naissance',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _isSaving ? null : _pickDob,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: MerchantOnboardingColors.bgDark2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasDob
                      ? MerchantOnboardingColors.primaryGold
                      : MerchantOnboardingColors.borderColor,
                  width: hasDob ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: hasDob
                        ? MerchantOnboardingColors.primaryGold
                        : MerchantOnboardingColors.textGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dobText,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: hasDob
                            ? MerchantOnboardingColors.textLight
                            : MerchantOnboardingColors.textGrey,
                        fontWeight: hasDob ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: MerchantOnboardingColors.textGrey,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildGoldButton(
            label: 'Suivant',
            enabled: _canProceedDob && !_isSaving,
            onTap: _goNext,
          ),
        ],
      ),
    );
  }

  Widget _buildCityStep() {
    final hasCity =
        _selectedCity != null && _selectedCity!.trim().isNotEmpty;
    return ResponsiveScrollBody(
      horizontalPadding: 24,
      verticalPadding: 0,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantOnboardingColors.bgDark2,
              border: Border.all(
                color: MerchantOnboardingColors.primaryGold,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.location_city_rounded,
              size: 40,
              color: MerchantOnboardingColors.primaryGold,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Dans quelle ville êtes-vous ?',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Nous vous montrerons les commerces proches de chez vous.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.5,
              color: MerchantOnboardingColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _isSaving
                ? null
                : () => CitySelectionModal.show(
                      context,
                      cities: frenchCities,
                      selectedCity: _selectedCity,
                      onCitySelected: (city) {
                        _onCitySelected(city);
                      },
                      onValidateCity: () {},
                    ),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: MerchantOnboardingColors.bgDark2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasCity
                      ? MerchantOnboardingColors.primaryGold
                      : MerchantOnboardingColors.bgDark2,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: hasCity
                        ? MerchantOnboardingColors.primaryGold
                        : MerchantOnboardingColors.textGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasCity
                          ? _selectedCity!
                          : 'Sélectionnez votre ville',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: hasCity
                            ? MerchantOnboardingColors.textLight
                            : MerchantOnboardingColors.textGrey,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: MerchantOnboardingColors.textGrey,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildGoldButton(
            label: 'Suivant',
            enabled: hasCity && !_isSaving,
            onTap: _goNext,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoAvatar() {
    final local = _localImagePath?.trim();
    if (local != null && local.isNotEmpty) {
      return Image.file(File(local), fit: BoxFit.cover);
    }
    final oauth = _oauthPhotoUrl?.trim();
    if (isUsableOAuthProfilePhotoUrl(oauth)) {
      return Image.network(
        oauth!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person_outline_rounded,
          size: 48,
          color: MerchantOnboardingColors.primaryGold,
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: MerchantOnboardingColors.primaryGold,
              ),
            ),
          );
        },
      );
    }
    return const Icon(
      Icons.add_a_photo_outlined,
      size: 48,
      color: MerchantOnboardingColors.primaryGold,
    );
  }

  Widget _buildPhotoStep() {
    final hasOAuthOnly = _hasPhotoPreview &&
        (_localImagePath == null || _localImagePath!.trim().isEmpty) &&
        isUsableOAuthProfilePhotoUrl(_oauthPhotoUrl);

    return ResponsiveScrollBody(
      horizontalPadding: 24,
      verticalPadding: 0,
      child: Column(
        children: [
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _isSaving ? null : _pickPhoto,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantOnboardingColors.bgDark2,
                border: Border.all(
                  color: MerchantOnboardingColors.primaryGold,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildPhotoAvatar(),
            ),
          ),
          if (hasOAuthOnly) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: MerchantOnboardingColors.primaryGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: MerchantOnboardingColors.primaryGold.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'Importée depuis votre compte',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MerchantOnboardingColors.primaryGold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Text(
            'Photo de profil',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            hasOAuthOnly
                ? 'Nous avons récupéré votre photo. Gardez-la ou choisissez-en une autre.'
                : _hasPhotoPreview
                    ? 'Vérifiez votre photo avant de continuer.'
                    : 'Prenez une photo ou choisissez-en une dans la galerie pour personnaliser votre profil.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: MerchantOnboardingColors.textGrey,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _isSaving ? null : _pickPhoto,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(
                  color: MerchantOnboardingColors.primaryGold,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasOAuthOnly
                        ? Icons.swap_horiz_rounded
                        : Icons.photo_library_outlined,
                    color: MerchantOnboardingColors.primaryGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasOAuthOnly
                        ? 'Choisir une autre photo'
                        : 'Prendre ou choisir une photo',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MerchantOnboardingColors.primaryGold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildGoldButton(
            label: hasOAuthOnly ? 'Garder cette photo' : 'Terminer',
            enabled: !_isSaving && _hasPhotoPreview,
            onTap: () => _finish(skipPhoto: false),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _isSaving ? null : () => _finish(skipPhoto: true),
            child: Text(
              'Passer cette étape',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: MerchantOnboardingColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
