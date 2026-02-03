import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/subcategory/subcategory_colors.dart';
import 'widgets/subcategory/subcategory_header.dart';
import 'widgets/subcategory/subcategory_footer.dart';
import 'widgets/subcategory/subcategory_card.dart';
import 'widgets/top_snackbar.dart';
import '../domain/entities/merchant_subcategory.dart';
import '../application/providers.dart';

/// Subcategory selection screen - shows subcategories for selected category
class SubcategorySelectionScreen extends ConsumerStatefulWidget {
  const SubcategorySelectionScreen({
    super.key,
    required this.categoryTitle,
    required this.subcategories,
    this.onSubcategorySelected,
    this.onBack,
    this.onNext,
  });

  final String categoryTitle;
  final List<MerchantSubcategory> subcategories;
  final ValueChanged<String>? onSubcategorySelected;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  ConsumerState<SubcategorySelectionScreen> createState() =>
      _SubcategorySelectionScreenState();
}

class _SubcategorySelectionScreenState
    extends ConsumerState<SubcategorySelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    // FIX HIGH 9: Proper cleanup to prevent memory leaks
    _animationController.dispose();
    super.dispose();
  }

  void _onSubcategoryTap(String subcategoryId) {
    // Store subcategory in controller
    final controller = ref.read(merchantOnboardingControllerProvider.notifier);
    controller.selectSubcategory(subcategoryId);

    // Show SnackBar feedback from top
    final subcategory = widget.subcategories.firstWhere(
      (c) => c.id == subcategoryId,
    );
    showTopSnackBar(
      context,
      'Sous-catégorie sélectionnée: ${subcategory.title.replaceAll('\n', ' ')}',
    );

    widget.onSubcategorySelected?.call(subcategoryId);
  }

  @override
  Widget build(BuildContext context) {
    const statusBarStyle = SystemUiOverlayStyle(
      statusBarColor: SubcategoryColors.bgDark1,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: SubcategoryColors.bgDark1,
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
        backgroundColor: SubcategoryColors.bgDark1,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Scrollable content
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: SubcategoryHeader(
                      animationController: _animationController,
                      onBack: widget.onBack ?? () {},
                      title: widget.categoryTitle,
                    ),
                  ),

                  // Subcategory Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final subcategory = widget.subcategories[index];
                          // Read selected subcategory from controller state
                          final selectedSubcategoryId = ref.watch(
                            merchantOnboardingControllerProvider,
                          ).selectedSubcategoryId;
                          return SubcategoryCard(
                            subcategory: subcategory,
                            isSelected: selectedSubcategoryId == subcategory.id,
                            onTap: () => _onSubcategoryTap(subcategory.id),
                            animationDelay: index * 40,
                          );
                        },
                        childCount: widget.subcategories.length,
                      ),
                    ),
                  ),

                  // Footer with bottom padding for button
                  SliverToBoxAdapter(
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 100),
                      child: SubcategoryFooter(),
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
                    color: SubcategoryColors.bgDark1,
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
                      child: Consumer(
                        builder: (context, ref, child) {
                          // Read selected subcategory from controller state
                          final selectedSubcategoryId = ref.watch(
                            merchantOnboardingControllerProvider,
                          ).selectedSubcategoryId;
                          return ElevatedButton(
                            onPressed: selectedSubcategoryId != null
                                ? () => widget.onNext?.call()
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SubcategoryColors.primaryGold,
                          disabledBackgroundColor:
                              SubcategoryColors.primaryGold.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                            shadowColor:
                                SubcategoryColors.primaryGold.withOpacity(0.3),
                            elevation: selectedSubcategoryId != null ? 6 : 0,
                          ),
                          child: Text(
                            'Suivant',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: selectedSubcategoryId != null
                                  ? SubcategoryColors.bgDark1
                                  : SubcategoryColors.textGrey.withOpacity(0.5),
                            ),
                          ),
                        );
                        },
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

