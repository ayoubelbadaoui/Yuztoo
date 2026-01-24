import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../application/state/auth_state.dart';
import '../../login/application/providers.dart';

/// Example presentation widget consuming the application layer via Riverpod.
class AuthStateBanner extends ConsumerWidget {
  const AuthStateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);

    return switch (state) {
      Authenticated(:final user) =>
        _Banner(text: 'Signed in as ${user.email ?? user.id}'),
      AuthLoading() => const _Banner(text: 'Signing in...'),
      AuthError(:final failure) => _Banner(text: failure.message),
      Unauthenticated() || AuthInitial() => const _Banner(text: 'Signed out'),
    };
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
