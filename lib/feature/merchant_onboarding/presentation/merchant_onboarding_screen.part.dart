part of 'merchant_onboarding_screen.dart';

extension _MerchantOnboardingScreenUi on _MerchantOnboardingScreenState {
  Widget _buildMerchantOnboardingScaffold(BuildContext context) {
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
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildProgressBar(1, 3),
              _buildHeader(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
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
                ),
              ),
              const OnboardingFooter(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: ElevatedButton(
                  onPressed: _selectedCategoryId == null ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MerchantOnboardingColors.primaryGold,
                    foregroundColor: MerchantOnboardingColors.bgDark1,
                    disabledBackgroundColor: MerchantOnboardingColors.primaryGold
                        .withValues(alpha: 0.3),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Continuer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int current, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_ios),
            color: MerchantOnboardingColors.primaryGold,
            iconSize: 20,
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
                minHeight: 6,
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          children: [
            const Text(
              'Dites-nous ce que vous faites?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: MerchantOnboardingColors.textLight,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              width: double.infinity,
              decoration: BoxDecoration(
                color: MerchantOnboardingColors.primaryGold
                    .withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
