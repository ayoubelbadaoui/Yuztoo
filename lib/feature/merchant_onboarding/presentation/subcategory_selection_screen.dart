import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/providers.dart';
import '../domain/entities/merchant_subcategory.dart';
import 'widgets/subcategory/subcategory_card.dart';
import 'widgets/subcategory/subcategory_colors.dart';
import 'widgets/subcategory/subcategory_footer.dart';
import 'widgets/subcategory/restaurant_subcategories.dart';

class SubcategorySelectionScreen extends ConsumerStatefulWidget {
  const SubcategorySelectionScreen({
    super.key,
    required this.onBack,
    required this.onNext,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  ConsumerState<SubcategorySelectionScreen> createState() =>
      _SubcategorySelectionScreenState();
}

class _SubcategorySelectionScreenState
    extends ConsumerState<SubcategorySelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  String? _selectedSubcategoryId;

  List<MerchantSubcategory> get _subcategories => RestaurantSubcategories.all;

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
    if (_selectedSubcategoryId == null) return;
    final selected =
        _subcategories.firstWhere((s) => s.id == _selectedSubcategoryId);
    ref.read(selectedMerchantSubcategoryTitleProvider.notifier).state =
        selected.title;
    widget.onNext();
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
                  color: SubcategoryColors.primaryGold,
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
                backgroundColor: SubcategoryColors.bgDark2,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  SubcategoryColors.primaryGold,
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

  Widget _buildHeader(String title) {
    return FadeTransition(
      opacity: _animationController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: SubcategoryColors.textLight,
                height: 1.25,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Précisez votre spécialité',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: SubcategoryColors.textGrey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final title = ref.watch(selectedMerchantCategoryTitleProvider) ??
        'Votre spécialité';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: SubcategoryColors.bgDark1,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: SubcategoryColors.bgDark1,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: SubcategoryColors.bgDark1,
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) widget.onBack();
          },
          child: SafeArea(
            bottom: false,
            child: Column(
            children: [
              _buildProgressBar(2, 3),
              _buildHeader(title),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory = _subcategories[index];
                    return SubcategoryCard(
                      subcategory: subcategory,
                      isSelected: _selectedSubcategoryId == subcategory.id,
                      animationDelay: index * 30,
                      onTap: () =>
                          setState(() => _selectedSubcategoryId = subcategory.id),
                    );
                  },
                ),
              ),
              const SubcategoryFooter(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 0, 20, (bottomPad > 0 ? bottomPad : 16) + 8),
                child: GestureDetector(
                  onTap: _selectedSubcategoryId == null ? null : _continue,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: _selectedSubcategoryId != null
                          ? const LinearGradient(
                              colors: [
                                Color(0xFFD4AF37),
                                SubcategoryColors.primaryGold,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _selectedSubcategoryId == null
                          ? SubcategoryColors.primaryGold
                              .withValues(alpha: 0.25)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _selectedSubcategoryId != null
                          ? [
                              BoxShadow(
                                color: SubcategoryColors.primaryGold
                                    .withValues(alpha: 0.35),
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
                          color: _selectedSubcategoryId != null
                              ? SubcategoryColors.bgDark1
                              : SubcategoryColors.textGrey
                                  .withValues(alpha: 0.5),
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
}
