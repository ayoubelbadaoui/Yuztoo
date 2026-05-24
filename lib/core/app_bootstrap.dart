import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feature/auth/core/application/providers.dart';
import '../feature/loading/application/screens.dart';
import 'infrastructure/firebase_providers.dart';

/// Ensures Firebase is initialized and wires base providers before rendering the UI.
class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseInit = ref.watch(firebaseInitializationProvider);

    return firebaseInit.when(
      data: (_) {
        // Starts listening to auth state immediately.
        ref.watch(authControllerProvider);
        return child;
      },
      loading: () => const MaterialApp(
        home: LoadingScreen(),
      ),
      error: (error, _) {
        const bg = Color(0xFF0E2A44);
        return MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: bg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFC9A227),
              brightness: Brightness.dark,
            ),
          ),
          home: Scaffold(
            backgroundColor: bg,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Impossible d\'initialiser Firebase : $error',
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
