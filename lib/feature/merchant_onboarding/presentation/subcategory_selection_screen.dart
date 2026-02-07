import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/subcategory/subcategory_colors.dart';
import 'widgets/subcategory/subcategory_header.dart';
import 'widgets/subcategory/subcategory_footer.dart';
import 'widgets/subcategory/subcategory_card.dart';
import 'widgets/top_snackbar.dart';
import '../domain/entities/merchant_subcategory.dart';

/// Subcategory selection screen - shows subcategories for selected category
class SubcategorySelectionScreen extends StatefulWidget {
  const SubcategorySelectionScreen({
    super.key,
    required this.categoryTitle,
    required this.subcategories,
    this.onSubcategorySelected,
    this.onBack,
    this.onNext,
  });

  static String get path => '/merchant-subcategory-selection';

  final String categoryTitle;
  final List<MerchantSubcategory> subcategories;
  final ValueChanged<String>? onSubcategorySelected;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  State<SubcategorySelectionScreen> createState() =>
      _SubcategorySelectionScreenState();
}

class _SubcategorySelectionScreenState
    extends State<SubcategorySelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _selectedSubcategoryId;

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
    _animationController.dispose();
    super.dispose();
  }

  void _onSubcategoryTap(String subcategoryId) {
    setState(() {
      _selectedSubcategoryId = subcategoryId;
    });

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
        onPopInvokedWithResult: (didPop, result) {
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
                          return SubcategoryCard(
                            subcategory: subcategory,
                            isSelected: _selectedSubcategoryId == subcategory.id,
                            onTap: () => _onSubcategoryTap(subcategory.id),
                            animationDelay: index * 40,
                          );
                        },
                        childCount: widget.subcategories.length,
                      ),
                    ),
                  ),

                  // Footer with bottom padding for button
                  const SliverToBoxAdapter(
                    child: Padding(
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
                        color: Colors.black.withValues(alpha: 0.2),
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
                        onPressed: _selectedSubcategoryId != null
                            ? () => widget.onNext?.call()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SubcategoryColors.primaryGold,
                          disabledBackgroundColor:
                              SubcategoryColors.primaryGold.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          shadowColor:
                              SubcategoryColors.primaryGold.withValues(alpha: 0.3),
                          elevation: _selectedSubcategoryId != null ? 6 : 0,
                        ),
                        child: Text(
                          'Suivant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedSubcategoryId != null
                                ? SubcategoryColors.bgDark1
                                : SubcategoryColors.textGrey.withValues(alpha: 0.5),
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

