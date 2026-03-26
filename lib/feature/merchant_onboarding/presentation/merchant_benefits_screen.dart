import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/benefits/benefits_colors.dart';
import 'widgets/benefits/benefits_data.dart';
import 'widgets/benefits/benefits_header.dart';
import 'widgets/benefits/benefits_subtitle.dart';
import 'widgets/benefits/benefit_card.dart';
import 'widgets/benefits/free_text.dart';

class MerchantBenefitsScreen extends StatefulWidget {
  const MerchantBenefitsScreen({
    super.key,
    required this.onBack,
    required this.onNext,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<MerchantBenefitsScreen> createState() => _MerchantBenefitsScreenState();
}

class _MerchantBenefitsScreenState extends State<MerchantBenefitsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

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

  Widget _buildProgressBar(int current, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_ios),
            color: BenefitsColors.primaryGold,
            iconSize: 20,
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: current / total,
                backgroundColor: BenefitsColors.bgDark2,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  BenefitsColors.primaryGold,
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: BenefitsColors.bgDark1,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: BenefitsColors.bgDark1,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: BenefitsColors.bgDark1,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildProgressBar(3, 3),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Column(
                  children: [
                    BenefitsHeader(animationController: _animationController),
                    const SizedBox(height: 12),
                    BenefitsSubtitle(animationController: _animationController),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  itemCount: BenefitsData.all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => BenefitCard(
                    benefit: BenefitsData.all[index],
                    animationDelay: index * 40,
                  ),
                ),
              ),
              FreeText(animationController: _animationController),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BenefitsColors.primaryGold,
                    foregroundColor: BenefitsColors.bgDark1,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Créer mon compte'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
