import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/benefits/benefits_colors.dart';
import 'widgets/benefits/benefits_header.dart';
import 'widgets/benefits/benefits_subtitle.dart';
import 'widgets/benefits/benefit_card.dart';
import 'widgets/benefits/free_text.dart';
import 'widgets/benefits/benefits_data.dart';
import '../../../core/shared/widgets/back_button.dart';

/// Merchant benefits screen - shows Yuztoo benefits
class MerchantBenefitsScreen extends StatefulWidget {
  const MerchantBenefitsScreen({
    super.key,
    this.onStartFree,
    this.onBack,
  });

  final VoidCallback? onStartFree;
  final VoidCallback? onBack;

  @override
  State<MerchantBenefitsScreen> createState() =>
      _MerchantBenefitsScreenState();
}

class _MerchantBenefitsScreenState extends State<MerchantBenefitsScreen>
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const statusBarStyle = SystemUiOverlayStyle(
      statusBarColor: BenefitsColors.bgDark1,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: BenefitsColors.bgDark1,
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
        backgroundColor: BenefitsColors.bgDark1,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Back button
                      if (widget.onBack != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: YBackButton(
                            onPressed: widget.onBack!,
                            backgroundColor: BenefitsColors.bgDark2,
                            borderColor: BenefitsColors.borderColor,
                            iconColor: BenefitsColors.textLight,
                          ),
                        ),
                      const SizedBox(height: 16),
                      BenefitsHeader(
                        animationController: _animationController,
                      ),
                      const SizedBox(height: 24),
                      BenefitsSubtitle(
                        animationController: _animationController,
                      ),
                      const SizedBox(height: 32),
                      _buildBenefitsList(),
                      const SizedBox(height: 32),
                      FreeText(
                        animationController: _animationController,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildCTAButton(),
            ],
          ),
        ),
      ),
        ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = BenefitsData.all;
    return Column(
      children: List.generate(
        benefits.length,
        (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BenefitCard(
              benefit: benefits[index],
              animationDelay: index * 100,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCTAButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            BenefitsColors.bgDark1,
            BenefitsColors.bgDark1.withOpacity(0.95),
            BenefitsColors.bgDark1.withOpacity(0.0),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: widget.onStartFree,
            style: ElevatedButton.styleFrom(
              backgroundColor: BenefitsColors.primaryGold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: BenefitsColors.primaryGold.withOpacity(0.4),
            ),
            child: const Text(
              'Démarrer gratuitement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BenefitsColors.bgDark1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

