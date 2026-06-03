import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/application/precache_network_images.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/image_crop_utils.dart';
import '../application/profile_view_providers.dart';
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
  bool _isClearingAllNews = false;
  // When true the offline warning card is hidden until the next cold start
  // or until the merchant goes back offline. The user dismissed it manually.
  bool _offlineBannerDismissed = false;

  void _dismissOfflineBanner() =>
      setState(() => _offlineBannerDismissed = true);
  String? _precachedImageKey;
  final _imagePicker = ImagePicker();
  /// URLs whose Firestore removal is in-flight — excluded from the displayed
  /// list immediately (optimistic UI) and used to avoid concurrent-write races.
  final Set<String> _pendingDeleteUrls = {};

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
    final cropped = await cropImage(picked.path);
    if (!mounted) return;

    setState(() => _isUploadingNewsImage = true);
    final merchantId = _merchantIdForStorefront(storefront);

    final uploadResult =
        await ref.read(storage_providers.uploadNewsImageProvider).call(
              filePath: cropped ?? picked.path,
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

  Future<void> _deleteNewsImage(
      Storefront storefront, String imageUrl) async {
    // Guard against re-entrant delete (e.g. user taps the same × twice).
    if (_pendingDeleteUrls.contains(imageUrl)) return;

    setState(() => _pendingDeleteUrls.add(imageUrl));
    final merchantId = _merchantIdForStorefront(storefront);

    // Exclude EVERY in-flight pending delete from the new list so concurrent
    // taps on different images don't overwrite each other's removal.
    final updatedUrls = storefront.newsImageUrls
        .where((u) => !_pendingDeleteUrls.contains(u))
        .toList();

    try {
      final result =
          await ref.read(merchant_providers.updateStorefrontProvider).call(
                merchantId: merchantId,
                newsImageUrls: updatedUrls,
              );
      result.fold(
        (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de la suppression')),
          );
        },
        (_) {
          // Best-effort Storage cleanup (same logic as edit-profile _deleteImage).
          _tryDeleteStorageFile(imageUrl);
          ref.invalidate(storefrontProvider);
        },
      );
    } finally {
      if (mounted) setState(() => _pendingDeleteUrls.remove(imageUrl));
    }
  }

  Future<void> _clearAllNewsImages(Storefront storefront) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer toutes les photos ?'),
        content: const Text(
            'Toutes les photos de votre actualité seront définitivement supprimées. Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Tout supprimer',
              style: TextStyle(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isClearingAllNews = true);
    final merchantId = _merchantIdForStorefront(storefront);
    final urlsToDelete = List<String>.from(storefront.newsImageUrls);

    try {
      final result =
          await ref.read(merchant_providers.updateStorefrontProvider).call(
                merchantId: merchantId,
                newsImageUrls: [],
              );
      result.fold(
        (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de la suppression')),
          );
        },
        (_) {
          // Best-effort Storage cleanup for every image.
          for (final url in urlsToDelete) {
            _tryDeleteStorageFile(url);
          }
          ref.invalidate(storefrontProvider);
        },
      );
    } finally {
      if (mounted) setState(() => _isClearingAllNews = false);
    }
  }

  /// Parses a Firebase Storage download URL and fires a best-effort delete.
  /// The URL format is: .../o/merchants%2F{id}%2Fnews%2F{file}?...
  void _tryDeleteStorageFile(String url) {
    try {
      final uri = Uri.parse(url);
      final encoded = uri.pathSegments
          .skipWhile((s) => s != 'o')
          .skip(1)
          .firstOrNull;
      if (encoded != null && encoded.isNotEmpty) {
        final storagePath = Uri.decodeComponent(encoded);
        ref
            .read(storage_providers.deleteStorageImageProvider)
            .call(storagePath);
      }
    } catch (_) {
      // Non-fatal: Firestore is already updated.
    }
  }

  String _merchantIdForStorefront(Storefront storefront) => storefront.id;

  Future<void> _setMerchantPublished(
      Storefront storefront, bool published) async {
    if (storefront.isPublished == published) return;
    final merchantId = _merchantIdForStorefront(storefront);
    if (mounted) setState(() {
      _isPublishingToggle = true;
      // Re-show the banner the next time the merchant goes offline.
      if (published) _offlineBannerDismissed = false;
    });
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
    final cropped = await cropImage(
      picked.path,
      ratioX: isBanner ? 16 : 1,
      ratioY: isBanner ? 9 : 1,
    );
    if (!mounted) return;

    setState(() => _isUploadingBannerProfile = true);
    final merchantId = _merchantIdForStorefront(storefront);
    final imagePath = cropped ?? picked.path;
    try {
      final result =
          await ref.read(merchant_providers.updateStorefrontProvider).call(
                merchantId: merchantId,
                bannerFilePath: isBanner ? imagePath : null,
                logoFilePath: isBanner ? null : imagePath,
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
