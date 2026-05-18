import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../../client_notification/infrastructure/client_notification_repository_provider.dart';
import '../../merchant/application/providers.dart'
    show currentMerchantForOwnerProvider;
import '../domain/entities/active_validation_request.dart';
import '../infrastructure/active_validation_repository_provider.dart';
import '../infrastructure/client_loyalty_repository_provider.dart';
import 'use_cases/cancel_active_validation.dart';
import 'use_cases/confirm_active_validation.dart';
import 'use_cases/request_active_validation.dart';
import 'use_cases/simulate_client_active_validation.dart';

// ─── Use-case providers ────────────────────────────────────────────────────────

final requestActiveValidationProvider =
    Provider<RequestActiveValidation>((ref) {
  return RequestActiveValidation(
    ref.watch(activeValidationRepositoryProvider),
  );
});

final confirmActiveValidationProvider =
    Provider<ConfirmActiveValidation>((ref) {
  return ConfirmActiveValidation(
    ref.watch(clientLoyaltyRepositoryProvider),
    ref.watch(clientNotificationRepositoryProvider),
  );
});

final cancelActiveValidationProvider =
    Provider<CancelActiveValidation>((ref) {
  return CancelActiveValidation(
    ref.watch(activeValidationRepositoryProvider),
  );
});

final simulateClientActiveValidationProvider =
    Provider<SimulateClientActiveValidation>((ref) {
  return SimulateClientActiveValidation(
    ref.watch(activeValidationRepositoryProvider),
  );
});

// ─── Stream providers ──────────────────────────────────────────────────────────

/// The client's own live session for a given merchant. Emits null when no
/// active doc exists. Drives the loyalty card banner and the storefront
/// waiting sheet.
final clientActiveValidationSessionProvider = StreamProvider.autoDispose
    .family<ActiveValidationRequest?, String>((ref, merchantId) {
  final auth = ref.watch(auth_providers.authStateProvider);
  if (auth is! Authenticated) {
    return Stream<ActiveValidationRequest?>.value(null);
  }
  final repo = ref.watch(activeValidationRepositoryProvider);
  return repo.watchClientSession(
    merchantId: merchantId,
    clientUid: auth.user.id,
  );
});

/// Awaiting sessions under the currently active merchant (the one whose
/// dashboard the user owns). Empty for non-merchants. Drives the global
/// merchant-shell popup.
final merchantActiveValidationQueueProvider =
    StreamProvider.autoDispose<List<ActiveValidationRequest>>((ref) {
  final auth = ref.watch(auth_providers.authStateProvider);
  if (auth is! Authenticated) {
    return Stream<List<ActiveValidationRequest>>.value(
      const <ActiveValidationRequest>[],
    );
  }
  final merchantAsync = ref.watch(currentMerchantForOwnerProvider);
  return merchantAsync.when(
    data: (merchant) {
      if (merchant == null || merchant.ownerUid != auth.user.id) {
        return Stream<List<ActiveValidationRequest>>.value(
          const <ActiveValidationRequest>[],
        );
      }
      return ref
          .watch(activeValidationRepositoryProvider)
          .watchMerchantQueue(merchant.id);
    },
    loading: () => Stream<List<ActiveValidationRequest>>.value(
      const <ActiveValidationRequest>[],
    ),
    error: (_, __) => Stream<List<ActiveValidationRequest>>.value(
      const <ActiveValidationRequest>[],
    ),
  );
});
