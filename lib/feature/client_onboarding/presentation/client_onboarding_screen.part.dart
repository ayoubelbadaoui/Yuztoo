part of 'client_onboarding_screen.dart';

extension _ClientOnboardingScreenUi on _ClientOnboardingScreenState {
  Widget _buildProgressBar() {
    return Padding(
      // iOS spec: 44pt tall nav region, 16pt horizontal gutter.
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                          .withValues(alpha: 0.25),
                  size: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              // iOS native progress is a hairline. 2px reads as cleaner
              // than the previous 6px chunky bar.
              borderRadius: BorderRadius.circular(2),
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
                    minHeight: 2,
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
          const SizedBox(height: 56),
          _buildStepHero(Icons.waving_hand_rounded),
          const SizedBox(height: 32),
          _buildStepTitle('Bienvenue'),
          const SizedBox(height: 12),
          _buildStepSubtitle(
              'Complétez votre profil en quelques étapes pour commencer à utiliser votre espace client.'),
          const SizedBox(height: 40),
          _buildGoldButton(
            label: 'Commencer',
            enabled: !_isSaving,
            onTap: _goNext,
          ),
        ],
      ),
    );
  }

  /// Shared Apple-style hero: solid gold icon, no container or border. The
  /// previous "circle with gold ring" chrome read as Material; Apple's own
  /// onboarding (Watch setup, AirPods, Migration Assistant) puts a single
  /// large icon directly on the background.
  Widget _buildStepHero(IconData icon) {
    return Icon(
      icon,
      size: 56,
      color: MerchantOnboardingColors.primaryGold,
    );
  }

  /// Display-sized title: 28pt semibold with tight letter spacing, the
  /// iOS large-title rhythm. Always white, always centered.
  Widget _buildStepTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: MerchantOnboardingColors.textLight,
        letterSpacing: -0.6,
        height: 1.15,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Body subtitle: 15pt, comfortable line-height, soft grey. Sits directly
  /// under the title with a 12pt gap (smaller than the previous 16 because
  /// the tighter title leading needs less air below).
  Widget _buildStepSubtitle(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 15,
        height: 1.45,
        color: MerchantOnboardingColors.textGrey,
        letterSpacing: -0.1,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildNameStep() {
    return ResponsiveScrollBody(
      horizontalPadding: 24,
      verticalPadding: 0,
      child: Column(
        children: [
          const SizedBox(height: 56),
          _buildStepHero(Icons.person_outline_rounded),
          const SizedBox(height: 32),
          _buildStepTitle('Comment vous appelez-vous ?'),
          const SizedBox(height: 32),
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
    // iOS-style continuous pill. Single solid gold (no gradient, no drop
    // shadow) — iOS native CTAs use a flat fill and rely on the corner
    // radius + typography to feel premium. The previous diagonal
    // gradient + glow read as decorative rather than luxe.
    const goldEnabled = Color(0xFFD4A017);
    const goldDisabled = Color(0x66D4A017); // 0.4 alpha
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: enabled ? goldEnabled : goldDisabled,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: enabled
                  ? const Color(0xFF0E2A44)
                  : const Color(0xFF0E2A44).withValues(alpha: 0.45),
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
          const SizedBox(height: 56),
          _buildStepHero(Icons.cake_outlined),
          const SizedBox(height: 32),
          _buildStepTitle('Date de naissance'),
          const SizedBox(height: 32),
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
          const SizedBox(height: 56),
          _buildStepHero(Icons.location_city_rounded),
          const SizedBox(height: 32),
          _buildStepTitle('Dans quelle ville êtes-vous ?'),
          const SizedBox(height: 12),
          _buildStepSubtitle(
              'Nous vous montrerons les commerces proches de chez vous.'),
          const SizedBox(height: 32),
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
          _buildStepTitle('Photo de profil'),
          const SizedBox(height: 12),
          _buildStepSubtitle(
            hasOAuthOnly
                ? 'Nous avons récupéré votre photo. Gardez-la ou choisissez-en une autre.'
                : _hasPhotoPreview
                    ? 'Vérifiez votre photo avant de continuer.'
                    : 'Prenez une photo ou choisissez-en une dans la galerie pour personnaliser votre profil.',
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
