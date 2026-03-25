import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_ios),
            color: SubcategoryColors.primaryGold,
            iconSize: 20,
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
                minHeight: 6,
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: SubcategoryColors.textLight,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              width: double.infinity,
              decoration: BoxDecoration(
                color: SubcategoryColors.primaryGold.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = ref.watch(selectedMerchantCategoryTitleProvider) ??
        'Choisissez votre type de commerce';

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
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildProgressBar(2, 3),
              _buildHeader(title),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.66,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory = _subcategories[index];
                    return SubcategoryCard(
                      subcategory: subcategory,
                      isSelected: _selectedSubcategoryId == subcategory.id,
                      animationDelay: index * 35,
                      onTap: () =>
                          setState(() => _selectedSubcategoryId = subcategory.id),
                    );
                  },
                ),
              ),
              const SubcategoryFooter(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: ElevatedButton(
                  onPressed: _selectedSubcategoryId == null ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SubcategoryColors.primaryGold,
                    foregroundColor: SubcategoryColors.bgDark1,
                    disabledBackgroundColor:
                        SubcategoryColors.primaryGold.withValues(alpha: 0.3),
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
