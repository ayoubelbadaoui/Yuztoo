import 'dart:async';
import 'package:flutter/material.dart';
import '../../loading/application/screens.dart';

/// Splash / loading surface shown while auth state initialises.
///
/// Uses the branded [LoadingScreen] design (spinner, brand name,
/// progress bar, decorative dots).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Important: Splash is used as a loading surface while providers resolve auth.
    // It must NOT force navigation unless explicitly requested by caller.
    if (widget.onComplete != null) {
      Timer(const Duration(seconds: 2), widget.onComplete!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const LoadingScreen();
  }
}
