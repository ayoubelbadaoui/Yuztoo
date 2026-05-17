part of 'merchant_onboarding_screen.dart';

extension _MerchantOnboardingScreenUi on _MerchantOnboardingScreenState {
  Widget _buildMerchantOnboardingScaffold(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantOnboardingColors.bgDark1,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MerchantOnboardingColors.bgDark1,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantOnboardingColors.bgDark1,
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) widget.onBack();
          },
          child: SafeArea(
            bottom: false,
            child: Column(
            children: [
              _buildProgressBar(1, 3),
              _buildHeader(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 520;
                    final crossAxisCount = wide ? 3 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: wide ? 0.88 : 0.82,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _MerchantOnboardingScreenState._categories.length,
                      itemBuilder: (context, index) {
                        final category =
                            _MerchantOnboardingScreenState._categories[index];
                        return CategoryCard(
                          category: category,
                          isSelected: _selectedCategoryId == category.id,
                          animationDelay: index * 45,
                          onTap: () => _selectCategory(category.id),
                        );
                      },
                    );
                  },
                ),
              ),
              const OnboardingFooter(),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, (bottomPad > 0 ? bottomPad : 16) + 8),
                child: _IphoneCta(
                  label: 'Continuer',
                  enabled: _selectedCategoryId != null,
                  onTap: _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildProgressBar(int current, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: widget.onBack,
                behavior: HitTestBehavior.opaque,
                // Chevron alone — the previous bordered circle around the
                // chevron read as Material-style. iOS nav back is just a
                // chevron + (optionally) a label.
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: MerchantOnboardingColors.primaryGold,
                  size: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: current / total,
                backgroundColor: MerchantOnboardingColors.bgDark2,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  MerchantOnboardingColors.primaryGold,
                ),
                minHeight: 2,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _animationController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre activité',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: MerchantOnboardingColors.textLight,
                height: 1.15,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sélectionnez votre secteur d\'activité',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: MerchantOnboardingColors.textGrey,
                height: 1.4,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared iOS-pill CTA — solid color, no gradient, no glow shadow. Used
/// across the merchant onboarding flow so every "Continuer" button feels
/// identical. The previous variant had a diagonal gold gradient + glow
/// that read as decorative; Apple's onboarding CTAs (Apple Watch / iCloud
/// setup) are flat single-color pills relying on typography + corner
/// radius for premium feel.
class _IphoneCta extends StatelessWidget {
  const _IphoneCta({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  static const _goldEnabled = MerchantOnboardingColors.primaryGold;
  static const _goldDisabled = Color(0x66D4A017);

  @override
  Widget build(BuildContext context) {
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
        height: 54,
        decoration: BoxDecoration(
          color: enabled ? _goldEnabled : _goldDisabled,
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
                  ? MerchantOnboardingColors.bgDark1
                  : MerchantOnboardingColors.bgDark1.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}
