import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/entities/force_update_config.dart';
import '../domain/force_update_decision.dart';
import '../domain/repositories/i_force_update_repository.dart';
import '../infrastructure/firestore_force_update_repository.dart';
import '../infrastructure/installed_app_version_reader.dart';

final forceUpdateRepositoryProvider = Provider<IForceUpdateRepository>((ref) {
  return FirestoreForceUpdateRepository(ref.watch(firebaseFirestoreProvider));
});

final installedAppVersionReaderProvider =
    Provider<InstalledAppVersionReader>((ref) {
  return const InstalledAppVersionReader();
});

/// Installed PackageInfo — refreshed on resume via [refreshForceUpdateProviders].
final installedAppVersionProvider =
    FutureProvider<InstalledAppVersion>((ref) async {
  return ref.watch(installedAppVersionReaderProvider).read();
});

/// Live CRM config. Missing / error → disabled (fail open until we know).
final forceUpdateConfigProvider = StreamProvider<ForceUpdateConfig>((ref) {
  return ref.watch(forceUpdateRepositoryProvider).watchConfig();
});

/// Automatic decision: installed build vs CRM platform min.
///
/// - Loading / error → not required (do not block the app on a flaky read).
/// - Once [required] is true, the UI hard-blocks until the store binary is newer.
final forceUpdateDecisionProvider = Provider<AsyncValue<ForceUpdateDecision>>(
  (ref) {
    final configAsync = ref.watch(forceUpdateConfigProvider);
    final installedAsync = ref.watch(installedAppVersionProvider);

    return configAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
      data: (config) {
        return installedAsync.when(
          loading: () => const AsyncValue.loading(),
          error: (e, st) => AsyncValue.error(e, st),
          data: (installed) => AsyncValue.data(
            evaluateForceUpdate(config: config, installed: installed),
          ),
        );
      },
    );
  },
);

/// True only when we positively know an update is mandatory.
final forceUpdateRequiredProvider = Provider<bool>((ref) {
  return ref.watch(forceUpdateDecisionProvider).valueOrNull?.required == true;
});

/// Call on app resume so a CRM flip (or a store install) is picked up.
void refreshForceUpdateProviders(WidgetRef ref) {
  ref.invalidate(installedAppVersionProvider);
  // StreamProvider re-subscribes; keep the live CRM watch hot after resume.
  ref.invalidate(forceUpdateConfigProvider);
}
