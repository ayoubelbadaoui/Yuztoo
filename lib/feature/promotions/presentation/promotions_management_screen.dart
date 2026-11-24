import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/utils/image_pick_with_source.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../../core/shared/widgets/yuztoo_pull_refresh.dart';
import '../../client_notification/application/providers.dart';
import '../../merchant/application/providers.dart'
    show activeMerchantIdProvider, currentMerchantForOwnerProvider;
import '../../merchant_partners/application/providers.dart'
    as partners_providers;
import '../../merchant_associations/presentation/association_section.dart';
import '../../merchant_partners/domain/entities/merchant_partner.dart';
import '../../merchant_partners/presentation/partner_invite_sheet.dart';
import '../application/providers.dart';
import '../domain/entities/promotion.dart';
import 'promotion_image_crop.dart';
import 'widgets/add_promo_sheet.dart';
import 'widgets/promo_analytics.dart';
import 'widgets/promo_card.dart';
import '../../../core/shared/widgets/yuztoo_tab_header.dart';

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
    extends ConsumerState<PromotionsManagementScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _isCreating = false;
  bool _showAllActive = false;
  bool _showAllExpired = false;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

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

    final merchantId = await ref.read(activeMerchantIdProvider.future);
    if (merchantId == null || merchantId.isEmpty || !context.mounted) return;

    _setCreating(true);
    final createPromotion = ref.read(createPromotionProvider);
    final createResult = await createPromotion.call(
      merchantId: merchantId,
      promotion: result.copyWith(merchantId: merchantId),
      imageFilePath: result.imagePath,
    );
    if (!context.mounted) return;
    _setCreating(false);

    createResult.fold(
      (failure) {
        // Promo may already exist when only the image step failed — refresh list.
        ref.invalidate(merchantPromotionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failure.message,
              style: merchantSnackBarTextOnWarmAccent(),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
      (savedPromo) {
        ref.invalidate(merchantPromotionsProvider);
        final wantedImage =
            result.imagePath != null && result.imagePath!.trim().isNotEmpty;
        final gotImage =
            savedPromo.imageUrl != null && savedPromo.imageUrl!.isNotEmpty;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wantedImage && !gotImage
                  ? 'Promotion créée — ajoutez la photo depuis la carte.'
                  : 'Promotion créée',
              style: merchantSnackBarTextOnGold(),
            ),
            backgroundColor: MerchantColors.gold,
          ),
        );
        // The Cloud Function onPromotionCreated already fans out a notification
        // to all followers on .onCreate — no Flutter-side call needed here to
        // avoid sending clients a duplicate notification.
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
          SnackBar(
            content: Text(
              failure.message,
              style: merchantSnackBarTextOnWarmAccent(),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
      (_) {
        ref.invalidate(merchantPromotionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Promotion supprimée',
              style: merchantSnackBarTextOnGold(),
            ),
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
          SnackBar(
            content: Text(
              failure.message,
              style: merchantSnackBarTextOnWarmAccent(),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
      (_) {
        ref.invalidate(merchantPromotionsProvider);

        // Notify followers only when the promotion goes online.
        if (isOnline) {
          final authState = ref.read(authStateProvider);
          if (authState is Authenticated) {
            ref.read(currentMerchantForOwnerProvider.future).then((merchant) {
              if (merchant == null) return;
              final merchantName = merchant.name.isNotEmpty
                  ? merchant.name
                  : authState.user.displayName ?? 'Votre commerce';
              ref.read(notifyFollowersOfPromotionProvider).call(
                    merchantId: merchant.id,
                    merchantName: merchantName,
                    promotion: updated,
                    callerUid: authState.user.id,
                  );
            });
          }
        }
      },
    );
  }

  bool _isUpdatingImage = false;

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
    if (source == null || !mounted) return;
    try {
      // Camera capture needs the runtime permission first — see safePickImage.
      final picked = await safePickImage(
        context: context,
        picker: _picker,
        source: source,
        maxWidth: promotionImagePickMaxSide.toDouble(),
        maxHeight: promotionImagePickMaxSide.toDouble(),
        imageQuality: 95,
      );
      if (picked == null || !context.mounted) return;

      final croppedPath = await cropPromotionImage(picked.path);
      // Keep original pick if crop is cancelled/fails (parity with create sheet).
      final imagePath = croppedPath ?? picked.path;
      if (!context.mounted) return;

      setState(() => _isUpdatingImage = true);
      final promo = promotions[index];
      final updatePromotion = ref.read(updatePromotionProvider);
      final result = await updatePromotion.call(
        promo,
        imageFilePath: imagePath,
      );
      if (!context.mounted) return;
      setState(() => _isUpdatingImage = false);

      result.fold(
        (failure) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                failure.message,
                style: merchantSnackBarTextOnWarmAccent(),
              ),
              backgroundColor: Colors.red.shade700,
            ),
          );
        },
        (_) {
          ref.invalidate(merchantPromotionsProvider);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Image mise à jour',
                style: merchantSnackBarTextOnGold(),
              ),
              backgroundColor: MerchantColors.gold,
            ),
          );
        },
      );
    } catch (_) {
      if (mounted) setState(() => _isUpdatingImage = false);
    }
  }

  void _setCreating(bool value) {
    setState(() => _isCreating = value);
  }

  // ignore: invalid_use_of_protected_member
  void _rebuild(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final promotionsAsync = ref.watch(merchantPromotionsProvider);
    return _buildPromotionsScaffold(context, promotionsAsync);
  }

  Future<void> _onRefresh() async {
    ref.invalidate(merchantPromotionsProvider);
    await ref
        .read(merchantPromotionsProvider.future)
        .catchError((_) => <Promotion>[]);
  }
}
