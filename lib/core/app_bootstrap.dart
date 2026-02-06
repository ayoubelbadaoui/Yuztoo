import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feature/auth/core/application/providers.dart';
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
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize Firebase: $error'),
          ),
        ),
      ),
    );
  }
}
