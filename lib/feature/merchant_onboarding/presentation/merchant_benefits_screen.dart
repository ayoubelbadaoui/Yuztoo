import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/benefits/benefits_colors.dart';
import 'widgets/benefits/benefits_data.dart';
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
                  color: BenefitsColors.primaryGold,
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
                backgroundColor: BenefitsColors.bgDark2,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  BenefitsColors.primaryGold,
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

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

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
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) widget.onBack();
          },
          child: SafeArea(
            bottom: false,
            child: Column(
            children: [
              _buildProgressBar(3, 3),

              // Header
              FadeTransition(
                opacity: _animationController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            BenefitsColors.textLight,
                            BenefitsColors.primaryGold,
                          ],
                          stops: [0.5, 1.0],
                        ).createShader(bounds),
                        child: Text(
                          'Yuztoo pour vous',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Restez dans la poche de vos clients',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: BenefitsColors.textGrey,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                  itemCount: BenefitsData.all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => BenefitCard(
                    benefit: BenefitsData.all[index],
                    animationDelay: index * 40,
                  ),
                ),
              ),

              FreeText(animationController: _animationController),

              // CTA — gradient gold, matches page 1 + 2
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 12, 20, (bottomPad > 0 ? bottomPad : 16) + 8),
                child: GestureDetector(
                  onTap: widget.onNext,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFD4AF37),
                          BenefitsColors.primaryGold,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: BenefitsColors.primaryGold
                              .withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: -2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: widget.onNext,
                        splashColor: Colors.white.withValues(alpha: 0.1),
                        child: Center(
                          child: Text(
                            'Créer mon compte',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: BenefitsColors.bgDark1,
                              letterSpacing: 0.2,
                            ),
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
