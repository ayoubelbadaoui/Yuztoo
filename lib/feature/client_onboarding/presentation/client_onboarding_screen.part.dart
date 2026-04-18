part of 'client_onboarding_screen.dart';

extension _ClientOnboardingScreenUi on _ClientOnboardingScreenState {
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: (_currentStep > 0 && !_isSaving) ? _goBack : null,
            icon: const Icon(
              Icons.arrow_back_ios,
              color: MerchantOnboardingColors.primaryGold,
              size: 20,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _goNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantOnboardingColors.primaryGold,
                foregroundColor: MerchantOnboardingColors.bgDark1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                'Commencer',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: MerchantOnboardingColors.textLight,
            ),
            cursorColor: MerchantOnboardingColors.primaryGold,
            decoration: InputDecoration(
              hintText: 'Ex: Marie Dupont',
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
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_canProceedName && !_isSaving) ? _goNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantOnboardingColors.primaryGold,
                disabledBackgroundColor:
                    MerchantOnboardingColors.primaryGold.withValues(alpha: 0.3),
                foregroundColor: MerchantOnboardingColors.bgDark1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _canProceedName ? 4 : 0,
              ),
              child: Text(
                'Suivant',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityStep() {
    final hasCity =
        _selectedCity != null && _selectedCity!.trim().isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: MerchantOnboardingColors.textGrey,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (hasCity && !_isSaving) ? _goNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantOnboardingColors.primaryGold,
                disabledBackgroundColor:
                    MerchantOnboardingColors.primaryGold.withValues(alpha: 0.3),
                foregroundColor: MerchantOnboardingColors.bgDark1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: hasCity ? 4 : 0,
              ),
              child: Text(
                'Suivant',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
              child: _localImagePath != null
                  ? Image.file(
                      File(_localImagePath!),
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.add_a_photo_outlined,
                      size: 48,
                      color: MerchantOnboardingColors.primaryGold,
                    ),
            ),
          ),
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
            'Ajoutez une photo depuis la galerie, ou passez cette étape.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: MerchantOnboardingColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : _pickPhoto,
              icon: const Icon(Icons.photo_library_outlined, size: 22),
              label: Text(
                'Choisir une photo',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: MerchantOnboardingColors.primaryGold,
                side: const BorderSide(
                  color: MerchantOnboardingColors.primaryGold,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () => _finish(skipPhoto: _localImagePath == null),
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantOnboardingColors.primaryGold,
                foregroundColor: MerchantOnboardingColors.bgDark1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                'Terminer',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isSaving ? null : () => _finish(skipPhoto: true),
            child: Text(
              'Passer',
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
