import 'package:flutter/material.dart';
import 'merchant_onboarding_colors.dart';

/// Header widget for merchant onboarding screen
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    super.key,
    required this.animationController,
  });

  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MerchantOnboardingColors.bgDark1, // Ensure consistent background
      child: FadeTransition(
        opacity: animationController,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          child: Column(
            children: [
              const Text(
                'Dites-nous ce que vous faites?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: MerchantOnboardingColors.textLight,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: MerchantOnboardingColors.primaryGold.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

