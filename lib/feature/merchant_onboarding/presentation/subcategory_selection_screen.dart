import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/onboarding_flow_provider.dart';
import '../application/providers.dart';
import '../domain/entities/merchant_subcategory.dart';
import 'widgets/subcategory/merchant_subcategory_catalog.dart';
import 'widgets/subcategory/subcategory_card.dart';
import 'widgets/subcategory/subcategory_colors.dart';
import 'widgets/subcategory/subcategory_footer.dart';

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

  /// Subcategories for the category the merchant picked on the previous
  /// step. Resolved once in [initState] so a rebuild during the auto-skip
  /// post-frame callback can't flicker the grid before navigation lands.
  late final List<MerchantSubcategory> _subcategories;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    final categoryId =
        ref.read(selectedMerchantCategoryIdProvider);
    _subcategories = MerchantSubcategoryCatalog.forCategory(categoryId);

    // Categories without a curated subcategory list (retail, beauty,
    // fitness, services, other for now) should NOT block the merchant
    // on an empty grid. Skip directly to the next step — the merchant
    // already specified their domain via the top-level category, and
    // the profile form will collect any further detail. Use a
    // post-frame callback because we cannot call widget.onNext()
    // during build / initState.
    if (_subcategories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Make sure no stale subcategory leaks through from a previous run.
        ref
            .read(selectedMerchantSubcategoryTitleProvider.notifier)
            .state = null;
        widget.onNext();
      });
    }
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
    ref.read(onboardingFlowProvider.notifier).setSubcategoryTitle(selected.title);
    widget.onNext();
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
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: SubcategoryColors.primaryGold,
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
                backgroundColor: SubcategoryColors.bgDark2,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  SubcategoryColors.primaryGold,
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

  Widget _buildHeader(String title) {
    return FadeTransition(
      opacity: _animationController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: SubcategoryColors.textLight,
                height: 1.15,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Précisez votre spécialité',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: SubcategoryColors.textGrey,
                height: 1.4,
                letterSpacing: -0.1,
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
                child: _SubcategoryCta(
                  label: 'Continuer',
                  enabled: _selectedSubcategoryId != null,
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
}

/// iOS-pill CTA — mirrors the `_IphoneCta` in
/// merchant_onboarding_screen.part.dart. Kept as a local copy here to avoid
/// pulling that file's `part` plumbing into a separately-scoped screen.
class _SubcategoryCta extends StatelessWidget {
  const _SubcategoryCta({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const goldEnabled = SubcategoryColors.primaryGold;
    const goldDisabled = Color(0x66D4A017);
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
                  ? SubcategoryColors.bgDark1
                  : SubcategoryColors.bgDark1.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}
