import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import 'use_cases/update_service_settings.dart';

export '../../auth/core/application/providers.dart' show authControllerProvider;
export '../../merchant/application/providers.dart'
    show currentMerchantForOwnerProvider, updateGratificationConfigProvider;

final updateServiceSettingsProvider = Provider<UpdateServiceSettings>((ref) {
  final repo = ref.watch(merchantRepositoryProvider);
  return UpdateServiceSettings(repo);
});

/// Current logged-in merchant's ID (for writes). Returns null when unauthenticated.
final currentMerchantIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(auth_providers.authStateProvider);
  if (authState is! Authenticated) return null;
  return authState.user.id;
});
