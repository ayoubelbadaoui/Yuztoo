import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/storage_repository_provider.dart';
import 'use_cases/upload_banner.dart';
import 'use_cases/upload_client_avatar.dart';
import 'use_cases/upload_logo.dart';
import 'use_cases/upload_news_image.dart';
import 'use_cases/delete_storage_image.dart';

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

/// Provider for UploadNewsImage use case.
final uploadNewsImageProvider = Provider<UploadNewsImage>((ref) {
  final repository = ref.watch(storageRepositoryProvider);
  return UploadNewsImage(repository);
});

/// Provider for client profile avatar upload.
final uploadClientAvatarProvider = Provider<UploadClientAvatar>((ref) {
  final repository = ref.watch(storageRepositoryProvider);
  return UploadClientAvatar(repository);
});

final deleteStorageImageProvider = Provider<DeleteStorageImage>((ref) {
  final repository = ref.watch(storageRepositoryProvider);
  return DeleteStorageImage(repository);
});
