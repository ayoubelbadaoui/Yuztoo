import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/merchant_category.dart';
import '../application/providers.dart';
import 'widgets/onboarding_footer.dart';
import 'widgets/category_card.dart';
import 'widgets/merchant_onboarding_colors.dart';

class MerchantOnboardingScreen extends StatefulWidget {
  const MerchantOnboardingScreen({
    super.key,
    required this.onBack,
    required this.onNext,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<MerchantOnboardingScreen> createState() => _MerchantOnboardingScreenState();
}

class _MerchantOnboardingScreenState extends State<MerchantOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  String? _selectedCategoryId;

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
                color: MerchantOnboardingColors.primaryGold.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _categories = <MerchantCategory>[
    MerchantCategory(
      id: 'restaurant',
      title: 'Restaurant',
      description: 'Restaurants, cafés, bars',
      placeholderColorHex: '#FF9800',
    ),
    MerchantCategory(
      id: 'retail',
      title: 'Commerce de détail',
      description: 'Boutiques, magasins',
      placeholderColorHex: '#2196F3',
    ),
    MerchantCategory(
      id: 'beauty',
      title: 'Beauté & Bien-être',
      description: 'Salons, spas',
      placeholderColorHex: '#E91E63',
    ),
    MerchantCategory(
      id: 'fitness',
      title: 'Sport & Fitness',
      description: 'Salles de sport',
      placeholderColorHex: '#4CAF50',
    ),
    MerchantCategory(
      id: 'services',
      title: 'Services',
      description: 'Services professionnels',
      placeholderColorHex: '#9C27B0',
    ),
    MerchantCategory(
      id: 'other',
      title: 'Autre',
      description: 'Autres commerces',
      placeholderColorHex: '#9E9E9E',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_selectedCategoryId == null) return;
    final selected = _categories.firstWhere((c) => c.id == _selectedCategoryId);
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(selectedMerchantCategoryTitleProvider.notifier).state = selected.title;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
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
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return CategoryCard(
                      category: category,
                      isSelected: _selectedCategoryId == category.id,
                      animationDelay: index * 45,
                      onTap: () => setState(() => _selectedCategoryId = category.id),
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
                    disabledBackgroundColor:
                        MerchantOnboardingColors.primaryGold.withValues(alpha: 0.3),
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
}
