import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/merchant_category.dart';
import '../application/providers.dart';
import 'widgets/onboarding_footer.dart';
import 'widgets/category_card.dart';
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

  void _selectCategory(String id) {
    setState(() => _selectedCategoryId = id);
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
        _categories.firstWhere((c) => c.id == _selectedCategoryId);
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(selectedMerchantCategoryTitleProvider.notifier).state =
        selected.title;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) => _buildMerchantOnboardingScaffold(context);
}
