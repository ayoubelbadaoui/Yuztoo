import 'package:flutter/material.dart';
import 'subcategory_colors.dart';
import '../../../../../core/shared/widgets/back_button.dart';

/// Header widget for subcategory selection screen
class SubcategoryHeader extends StatelessWidget {
  const SubcategoryHeader({
    super.key,
    required this.animationController,
    required this.onBack,
    required this.title,
  });

  final AnimationController animationController;
  final VoidCallback onBack;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SubcategoryColors.bgDark1,
      child: FadeTransition(
        opacity: animationController,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: YBackButton(
                  onPressed: onBack,
                  iconColor: SubcategoryColors.textLight,
                ),
              ),
              const SizedBox(height: 20),
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
      ),
    );
  }
}

