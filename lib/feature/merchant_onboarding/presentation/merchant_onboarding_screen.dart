import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/infrastructure/logger_service.dart';
import '../../../core/shared/widgets/overflow_scroll_text.dart';
import '../application/onboarding_flow_provider.dart';
import '../application/providers.dart';
import '../domain/entities/merchant_audience.dart';
import '../domain/entities/merchant_category.dart';
import 'widgets/onboarding_footer.dart';
import 'widgets/category_card.dart';
import 'widgets/merchant_category_catalog.dart';
import 'widgets/merchant_onboarding_colors.dart';

part 'merchant_onboarding_screen.part.dart';

class MerchantOnboardingScreen extends StatefulWidget {
  const MerchantOnboardingScreen({
    super.key,
    required this.onBack,
    required this.onNext,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<MerchantOnboardingScreen> createState() =>
      _MerchantOnboardingScreenState();
}

class _MerchantOnboardingScreenState extends State<MerchantOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  String? _selectedCategoryId;

  /// First level of the referential (Main → Catégorie → Business). Defaults
  /// to « Particuliers » — the core Yuztoo audience (commerces de proximité).
  MerchantAudience _audience = MerchantAudience.particuliers;

  List<MerchantCategory> get _visibleCategories =>
      MerchantCategoryCatalog.forAudience(_audience);

  void _selectCategory(String id) {
    MerchantCategory? selected;
    for (final c in _visibleCategories) {
      if (c.id == id) {
        selected = c;
        break;
      }
    }
    LoggerService.logInfo(
      'Onboarding category card tapped',
      context: <String, dynamic>{
        'categoryId': id,
        'categoryTitle': selected?.title,
        'audience': _audience.name,
        'merchantType': _audience.merchantTypeValue,
        'previousCategoryId': _selectedCategoryId,
      },
    );
    setState(() => _selectedCategoryId = id);
  }

  void _selectAudience(MerchantAudience audience) {
    if (audience == _audience) return;
    LoggerService.logInfo(
      'Onboarding audience toggled',
      context: <String, dynamic>{
        'audience': audience.name,
        'merchantType': audience.merchantTypeValue,
        'previousAudience': _audience.name,
        'clearedCategoryId': _selectedCategoryId,
      },
    );
    setState(() {
      _audience = audience;
      // The previous pick belongs to the other audience's grid — it must not
      // silently leak through to the subcategory step / persisted data.
      _selectedCategoryId = null;
    });
  }

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
    final selected =
        _visibleCategories.firstWhere((c) => c.id == _selectedCategoryId);
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(selectedMerchantCategoryTitleProvider.notifier).state =
        selected.title;
    container.read(selectedMerchantCategoryIdProvider.notifier).state =
        selected.id;
    final flow = container.read(onboardingFlowProvider.notifier);
    // Persist into the onboarding flow (was previously only stored in the
    // UI-only StateProviders, so categoryId/categoryTitle never reached
    // CompleteMerchantOnboarding).
    flow.setCategory(selected.id, selected.title);
    // The audience choice determines merchant_type deterministically —
    // prefill it so the later « Particuliers / Professionnels » wizard step
    // arrives preselected (the merchant can still override it there).
    flow.setMerchantType(_audience.merchantTypeValue);
    // Reset any previously-chosen subcategory: if the merchant changes
    // category, the old subcategory pick belongs to a different list and
    // must not silently leak through (e.g. picking "Boulangerie" then
    // switching to "Beauté & Bien-être" would otherwise keep "Boulangerie"
    // as the subcategory).
    container.read(selectedMerchantSubcategoryTitleProvider.notifier).state =
        null;
    LoggerService.logInfo(
      'Onboarding category confirmed (Continuer)',
      context: <String, dynamic>{
        'categoryId': selected.id,
        'categoryTitle': selected.title,
        'audience': _audience.name,
        'merchantType': _audience.merchantTypeValue,
      },
    );
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) => _buildMerchantOnboardingScaffold(context);
}
