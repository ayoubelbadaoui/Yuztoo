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
                child: GestureDetector(
                  onTap: _selectedCategoryId == null ? null : _continue,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: _selectedCategoryId != null
                          ? const LinearGradient(
                              colors: [
                                Color(0xFFD4AF37),
                                MerchantOnboardingColors.primaryGold,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _selectedCategoryId == null
                          ? MerchantOnboardingColors.primaryGold.withValues(alpha: 0.25)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _selectedCategoryId != null
                          ? [
                              BoxShadow(
                                color: MerchantOnboardingColors.primaryGold.withValues(alpha: 0.35),
                                blurRadius: 16,
                                spreadRadius: -2,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Continuer',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _selectedCategoryId != null
                              ? MerchantOnboardingColors.bgDark1
                              : MerchantOnboardingColors.textGrey.withValues(alpha: 0.5),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: MerchantOnboardingColors.primaryGold,
                  size: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: current / total,
                backgroundColor: MerchantOnboardingColors.bgDark2,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  MerchantOnboardingColors.primaryGold,
                ),
                minHeight: 5,
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
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre activité',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: MerchantOnboardingColors.textLight,
                height: 1.25,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sélectionnez votre secteur d\'activité',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: MerchantOnboardingColors.textGrey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
