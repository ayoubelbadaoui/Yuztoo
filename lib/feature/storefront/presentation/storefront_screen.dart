import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/application/precache_network_images.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../application/providers.dart';
import 'widgets/storefront_colors.dart';
import 'widgets/banner_section.dart';
import 'widgets/merchant_info_section.dart';
import 'widgets/stats_cards.dart';
import 'widgets/navigation_tabs.dart';
import 'widgets/news_section.dart';
import 'widgets/hours_section.dart';
import 'storefront_edit_profile_screen.dart';
import '../application/profile_edit_state.dart';
import '../domain/entities/storefront.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../storage/application/providers.dart' as storage_providers;

part 'storefront_screen.part.dart';

/// Storefront screen - main UI for merchant storefront management
class StorefrontScreen extends ConsumerStatefulWidget {
  const StorefrontScreen({super.key, this.onNavigate, this.isDualProfile = false});

  final ValueChanged<String>? onNavigate;
  final bool isDualProfile;

  @override
  ConsumerState<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends ConsumerState<StorefrontScreen> {
  bool _hoursHydratedFromStorefront = false;
  bool _isUploadingNewsImage = false;
  bool _isUploadingBannerProfile = false;
  bool _isPublishingToggle = false;
  String? _precachedImageKey;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _uploadNewsImage(Storefront storefront) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 86,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingNewsImage = true);
    final merchantId = _merchantIdForStorefront(storefront);

    final uploadResult =
        await ref.read(storage_providers.uploadNewsImageProvider).call(
              filePath: picked.path,
              merchantId: merchantId,
            );

    final imageUrl = uploadResult.fold((_) => null, (url) => url);
    if (imageUrl == null) {
      if (!mounted) return;
      setState(() => _isUploadingNewsImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec du téléversement de l\'image')),
      );
      return;
    }

    final updatedUrls = [...storefront.newsImageUrls, imageUrl];
    final result =
        await ref.read(merchant_providers.updateStorefrontProvider).call(
              merchantId: merchantId,
              newsImageUrls: updatedUrls,
            );

    result.fold(
      (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la sauvegarde du contenu')),
        );
      },
      (_) {
        ref.invalidate(storefrontProvider);
      },
    );

    if (mounted) {
      setState(() => _isUploadingNewsImage = false);
    }
  }

  String _merchantIdForStorefront(Storefront storefront) => storefront.id;

  Future<void> _setMerchantPublished(
      Storefront storefront, bool published) async {
    if (storefront.isPublished == published) return;
    final merchantId = _merchantIdForStorefront(storefront);
    if (mounted) setState(() => _isPublishingToggle = true);
    final result =
        await ref.read(merchant_providers.updateStorefrontProvider).call(
              merchantId: merchantId,
              status: published ? 'active' : 'inactive',
            );
    if (mounted) setState(() => _isPublishingToggle = false);

    result.fold(
      (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible de changer la visibilité du commerce')),
        );
      },
      (_) {
        ref.invalidate(storefrontProvider);
      },
    );
  }

  Future<void> _pickAndUploadBannerOrProfile(
    Storefront storefront, {
    required bool isBanner,
    required bool fromCamera,
  }) async {
    final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: isBanner ? 1200 : 800,
      maxHeight: isBanner ? 600 : 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingBannerProfile = true);
    final merchantId = _merchantIdForStorefront(storefront);
    try {
      final result =
          await ref.read(merchant_providers.updateStorefrontProvider).call(
                merchantId: merchantId,
                bannerFilePath: isBanner ? picked.path : null,
                logoFilePath: isBanner ? null : picked.path,
              );

      if (!mounted) return;

      result.fold(
        (failure) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        },
        (_) {
          ref.invalidate(storefrontProvider);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBanner
                    ? 'Couverture mise à jour'
                    : 'Photo de profil mise à jour',
              ),
              backgroundColor: StorefrontColors.primaryGold,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingBannerProfile = false);
      }
    }
  }

  void _rebuildAfterHoursHydrate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final storefrontAsync = ref.watch(storefrontProvider);
    final activeTab = ref.watch(storefrontTabProvider);

    // When the vitrine refetches (invalidate / autoDispose / resume), clear
    // local UI state so hours and image precache align with fresh Firestore data.
    ref.listen(storefrontProvider, (previous, next) {
      if (next is AsyncLoading) {
        if (mounted) {
          setState(() {
            _hoursHydratedFromStorefront = false;
            _precachedImageKey = null;
          });
        }
      }
    });

    return _buildStorefrontBody(context, storefrontAsync, activeTab);

  }
}
