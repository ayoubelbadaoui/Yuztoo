import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/merchant_onboarding_colors.dart';
import 'widgets/onboarding_header.dart';
import 'widgets/onboarding_footer.dart';
import 'widgets/category_card.dart';
import 'widgets/top_snackbar.dart';
import '../../../core/shared/widgets/back_button.dart';
import '../domain/entities/merchant_category.dart';

/// Merchant onboarding screen - category selection
class MerchantOnboardingScreen extends StatefulWidget {
  const MerchantOnboardingScreen({
    super.key,
    this.onCategorySelected,
    this.onBack,
    this.onNext,
  });

  final ValueChanged<String>? onCategorySelected;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  State<MerchantOnboardingScreen> createState() =>
      _MerchantOnboardingScreenState();
}

class _MerchantOnboardingScreenState extends State<MerchantOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _selectedCategoryId;

  // Mock categories - in real app, these would come from domain/application layer
  static final List<MerchantCategory> _categories = [
    MerchantCategory(
      id: 'restaurant',
      title: 'Restaurant',
      description: 'Restaurants, cafés, bars et établissements de restauration',
      placeholderColorHex: '#FF9800', // Orange
    ),
    MerchantCategory(
      id: 'retail',
      title: 'Commerce de détail',
      description: 'Boutiques, magasins et points de vente',
      placeholderColorHex: '#2196F3', // Blue
    ),
    MerchantCategory(
      id: 'beauty',
      title: 'Beauté & Bien-être',
      description: 'Salons, spas, instituts de beauté',
      placeholderColorHex: '#E91E63', // Pink
    ),
    MerchantCategory(
      id: 'fitness',
      title: 'Sport & Fitness',
      description: 'Salles de sport, clubs sportifs',
      placeholderColorHex: '#4CAF50', // Green
    ),
    MerchantCategory(
      id: 'services',
      title: 'Services',
      description: 'Services professionnels et personnels',
      placeholderColorHex: '#9C27B0', // Purple
    ),
    MerchantCategory(
      id: 'other',
      title: 'Autre',
      description: 'Autres types de commerces',
      placeholderColorHex: '#9E9E9E', // Grey
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onCategoryTap(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });

    // Show SnackBar feedback from top
    final category = _categories.firstWhere((c) => c.id == categoryId);
    showTopSnackBar(
      context,
      'Catégorie sélectionnée: ${category.title}',
    );

    widget.onCategorySelected?.call(categoryId);
  }

  @override
  Widget build(BuildContext context) {
    const statusBarStyle = SystemUiOverlayStyle(
      statusBarColor: MerchantOnboardingColors.bgDark1,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: MerchantOnboardingColors.bgDark1,
      systemNavigationBarIconBrightness: Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyle,
      child: PopScope(
        canPop: false, // Use our custom navigation instead of route popping
        onPopInvoked: (didPop) {
          if (!didPop && widget.onBack != null) {
            widget.onBack!();
          }
        },
        child: Scaffold(
        backgroundColor: MerchantOnboardingColors.bgDark1,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Scrollable content
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Back button and Header
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        if (widget.onBack != null) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: YBackButton(
                                onPressed: widget.onBack!,
                                backgroundColor: MerchantOnboardingColors.bgDark2,
                                borderColor: MerchantOnboardingColors.borderColor,
                                iconColor: MerchantOnboardingColors.textLight,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        OnboardingHeader(
                          animationController: _animationController,
                        ),
                      ],
                    ),
                  ),

                  // Category Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = _categories[index];
                          return CategoryCard(
                            category: category,
                            isSelected: _selectedCategoryId == category.id,
                            onTap: () => _onCategoryTap(category.id),
                            animationDelay: index * 60,
                          );
                        },
                        childCount: _categories.length,
                      ),
                    ),
                  ),

                  // Footer with bottom padding for button
                  SliverToBoxAdapter(
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 100),
                      child: OnboardingFooter(),
                    ),
                  ),
                ],
              ),

              // Fixed "Suivant" button at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  decoration: BoxDecoration(
                    color: MerchantOnboardingColors.bgDark1,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _selectedCategoryId != null
                            ? () => widget.onNext?.call()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MerchantOnboardingColors.primaryGold,
                          disabledBackgroundColor:
                              MerchantOnboardingColors.primaryGold.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          shadowColor: MerchantOnboardingColors.primaryGold.withOpacity(0.3),
                          elevation: _selectedCategoryId != null ? 6 : 0,
                        ),
                        child: Text(
                          'Suivant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedCategoryId != null
                                ? MerchantOnboardingColors.bgDark1
                                : MerchantOnboardingColors.textGrey.withOpacity(0.5),
                          ),
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
}

