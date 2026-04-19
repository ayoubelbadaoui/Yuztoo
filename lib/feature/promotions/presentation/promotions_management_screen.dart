import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../client_notification/application/providers.dart';
import '../../merchant/application/providers.dart' show currentMerchantForOwnerProvider;
import '../application/providers.dart';
import '../domain/entities/promotion.dart';
import 'widgets/add_promo_sheet.dart';
import 'widgets/promo_analytics.dart';
import 'widgets/promo_card.dart';

part 'promotions_management_screen.part.dart';

/// Promotions management screen – loads from Firestore, saves add/delete/toggle.
class PromotionsManagementScreen extends ConsumerStatefulWidget {
  final void Function(String)? onNavigate;
  final VoidCallback? onBack;

  const PromotionsManagementScreen({super.key, this.onNavigate, this.onBack});

  @override
  ConsumerState<PromotionsManagementScreen> createState() =>
      _PromotionsManagementScreenState();
}

class _PromotionsManagementScreenState
    extends ConsumerState<PromotionsManagementScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isCreating = false;

  Future<void> _showAddPromoSheet() async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;

    final result = await showModalBottomSheet<Promotion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddPromoSheet(),
    );
    if (result == null || !context.mounted) return;

    _setCreating(true);
    final createPromotion = ref.read(createPromotionProvider);
    final createResult = await createPromotion.call(
      merchantId: authState.user.id,
      promotion: result.copyWith(merchantId: authState.user.id),
      imageFilePath: result.imagePath,
    );
    if (!context.mounted) return;
    _setCreating(false);

    createResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
      (savedPromo) async {
        ref.invalidate(merchantPromotionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Promotion créée'),
            backgroundColor: MerchantColors.gold,
          ),
        );

        // Notify all followers — fire and forget (non-blocking UI).
        final merchantAsync =
            await ref.read(currentMerchantForOwnerProvider.future);
        final merchantName =
            merchantAsync?.name ?? authState.user.displayName ?? 'Votre commerce';

        final notifyUseCase = ref.read(notifyFollowersOfPromotionProvider);
        await notifyUseCase.call(
          merchantId: authState.user.id,
          merchantName: merchantName,
          promotion: savedPromo,
        );
      },
    );
  }

  Future<void> _confirmDelete(Promotion promo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MerchantColors.navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer la promotion',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600, color: Colors.white),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer « ${promo.title} » ?',
          style: GoogleFonts.outfit(color: MerchantColors.textLightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: GoogleFonts.outfit(color: MerchantColors.textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer',
                style: GoogleFonts.outfit(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final deletePromotion = ref.read(deletePromotionProvider);
    final deleteResult = await deletePromotion.call(
      merchantId: promo.merchantId,
      promotionId: promo.id,
    );
    if (!context.mounted) return;
    deleteResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red.shade700),
        );
      },
      (_) {
        ref.invalidate(merchantPromotionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Promotion supprimée'),
            backgroundColor: MerchantColors.gold,
          ),
        );
      },
    );
  }

  Future<void> _onToggle(Promotion promo, bool isOnline) async {
    final updated = promo.copyWith(isOnline: isOnline);
    final updatePromotion = ref.read(updatePromotionProvider);
    final result = await updatePromotion.call(updated);
    if (!context.mounted) return;
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red.shade700),
        );
      },
      (_) {
        ref.invalidate(merchantPromotionsProvider);

        // Notify followers only when the promotion goes online.
        if (isOnline) {
          final authState = ref.read(authStateProvider);
          if (authState is Authenticated) {
            ref.read(currentMerchantForOwnerProvider.future).then((merchant) {
              final merchantName =
                  merchant?.name ?? authState.user.displayName ?? 'Votre commerce';
              ref.read(notifyFollowersOfPromotionProvider).call(
                    merchantId: authState.user.id,
                    merchantName: merchantName,
                    promotion: updated,
                  );
            });
          }
        }
      },
    );
  }

  Future<void> _pickImageForPromo(int index, List<Promotion> promotions) async {
    final messenger = ScaffoldMessenger.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: MerchantColors.navyCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: MerchantColors.gold),
                title: Text('Galerie',
                    style: GoogleFonts.outfit(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: MerchantColors.gold),
                title: Text('Caméra',
                    style: GoogleFonts.outfit(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked == null || !context.mounted) return;
      // TODO: upload image and update promotion in Firestore
      messenger.showSnackBar(
        const SnackBar(content: Text('Modification de l\'image à venir')),
      );
    } catch (_) {}
  }

  void _setCreating(bool value) {
    setState(() => _isCreating = value);
  }

  @override
  Widget build(BuildContext context) {
    final promotionsAsync = ref.watch(merchantPromotionsProvider);
    return _buildPromotionsScaffold(context, promotionsAsync);
  }
}
