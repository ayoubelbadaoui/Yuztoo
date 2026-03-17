import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/storage_repository_provider.dart';
import 'use_cases/upload_banner.dart';
import 'use_cases/upload_logo.dart';

/// Provider for UploadLogo use case.
final uploadLogoProvider = Provider<UploadLogo>((ref) {
  final repository = ref.watch(storageRepositoryProvider);
  return UploadLogo(repository);
});

/// Provider for UploadBanner use case.
final uploadBannerProvider = Provider<UploadBanner>((ref) {
  final repository = ref.watch(storageRepositoryProvider);
  return UploadBanner(repository);
});
