import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../../l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onComplete});

  static String get path => '/splash';

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Logo(),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.appTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.connectToShops,
                style: const TextStyle(color: Colors.white70),
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
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: YColors.secondary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'Y',
        style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
      ),
    );
  }
}
