import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../../core/shared/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Important: Splash is used as a loading surface while providers resolve auth.
    // It must NOT force navigation unless explicitly requested by caller.
    if (widget.onComplete != null) {
      Timer(const Duration(seconds: 2), widget.onComplete!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: YColors.primary,
      child: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Logo(),
              SizedBox(height: 22),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    // International standard: Splash logos use 40-50% of screen height
    // Examples: Uber (45%), Airbnb (48%), Instagram (42%)
    final screenH = MediaQuery.of(context).size.height;
    final logoSize = (screenH * 0.50).clamp(320.0, 450.0);

    return AppLogo(
      size: logoSize,
      fallback: Text(
        'Y',
        style: TextStyle(
          color: Colors.white,
          fontSize: logoSize * 0.33,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
