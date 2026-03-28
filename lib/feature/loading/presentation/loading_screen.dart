import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import 'widgets/background_orbs.dart';
import 'widgets/brand_name.dart';
import 'widgets/decorative_dots.dart';
import 'widgets/loading_progress_bar.dart';
import 'widgets/loading_spinner.dart';
import 'widgets/loading_text.dart';

/// Loading screen – pixel-faithful recreation of the HTML/CSS design.
///
/// Structure (matches the HTML exactly):
/// ```
/// Scaffold (bg: #0E2A44)
/// └── Stack (full screen)
///     ├── BackgroundOrbs        (absolute – orb-1 & orb-2)
///     ├── centered column       (spinner + brand + text + progress)
///     └── DecorativeDots        (absolute bottom 60, 3 pulsing dots)
/// ```
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgMain,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Stack(
          children: [
            BackgroundOrbs(),
            _MainContent(),
            DecorativeDots(),
          ],
        ),
      ),
    );
  }
}

/// Centered column: spinner → brand → loading text → progress bar.
class _MainContent extends StatelessWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingSpinner(),
            SizedBox(height: 40),
            BrandName(),
            SizedBox(height: 40),
            LoadingText(),
            SizedBox(height: 8),
            LoadingProgressBar(),
          ],
        ),
      ),
    );
  }
}
