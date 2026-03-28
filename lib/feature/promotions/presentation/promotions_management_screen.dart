import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../../../core/shared/constants/merchant_colors.dart';
import '../application/providers.dart' as promo_providers;
import '../domain/entities/promotion.dart';
import 'widgets/add_promo_sheet.dart';
import 'widgets/promo_analytics.dart';
import 'widgets/promo_card.dart';

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
    final authState = ref.read(auth_providers.authStateProvider);
    if (authState is! Authenticated) return;

    final result = await showModalBottomSheet<Promotion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddPromoSheet(),
    );
    if (result == null || !context.mounted) return;

    setState(() => _isCreating = true);
    final createPromotion = ref.read(promo_providers.createPromotionProvider);
    final createResult = await createPromotion.call(
      merchantId: authState.user.id,
      promotion: result.copyWith(merchantId: authState.user.id),
      imageFilePath: result.imagePath,
    );
    if (!context.mounted) return;
    setState(() => _isCreating = false);

    createResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
      (_) {
        ref.invalidate(promo_providers.merchantPromotionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Promotion créée'),
            backgroundColor: MerchantColors.gold,
          ),
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

    final deletePromotion = ref.read(promo_providers.deletePromotionProvider);
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
        ref.invalidate(promo_providers.merchantPromotionsProvider);
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
    final updatePromotion = ref.read(promo_providers.updatePromotionProvider);
    final result = await updatePromotion.call(updated);
    if (!context.mounted) return;
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red.shade700),
        );
      },
      (_) => ref.invalidate(promo_providers.merchantPromotionsProvider),
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

  @override
  Widget build(BuildContext context) {
    final promotionsAsync = ref.watch(promo_providers.merchantPromotionsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgHeader,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: promotionsAsync.when(
                data: (promotions) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 80,
                    ),
                    child: Column(
                      children: [
                        _buildAddPromoSection(),
                        if (promotions.isNotEmpty) _buildPromoList(promotions),
                        const PromoAnalytics(),
                        _buildNotificationsAutoButton(),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: MerchantColors.gold)),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Erreur: $err',
                      style: GoogleFonts.outfit(color: MerchantColors.textLightGrey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: Text(
              'Promotions',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── add promo tap area ─────────────────────────────────────────────────────

  Widget _buildAddPromoSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: _isCreating ? null : _showAddPromoSheet,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: MerchantColors.navyCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MerchantColors.gold.withValues(alpha: 0.5),
              width: 2,
              strokeAlign: BorderSide.strokeAlignCenter,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: MerchantColors.gold,
                ),
                child: const Center(
                  child: Icon(Icons.add,
                      color: MerchantColors.darkOverlay, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Ajoutez une promotion',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── notifications auto button (dashed card, same style as add-promo) ──────

  Widget _buildNotificationsAutoButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GestureDetector(
        onTap: () => widget.onNavigate?.call('notifications-auto'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: MerchantColors.navyCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MerchantColors.gold.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: MerchantColors.gold,
                ),
                child: const Center(
                  child: Icon(Icons.notifications_active_outlined,
                      color: MerchantColors.darkOverlay, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Notifications automatiques',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: MerchantColors.gold, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoList(List<Promotion> promotions) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          ...promotions.asMap().entries.map((entry) {
            final index = entry.key;
            final promo = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PromoCard(
                promo: promo,
                onToggle: (v) => _onToggle(promo, v),
                onDelete: () => _confirmDelete(promo),
                onPickImage: () => _pickImageForPromo(index, promotions),
              ),
            );
          }),
          Text(
            'Créez et publiez des promotions pour vos clients mais aussi pour la communauté Yuztoo locale',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textLightGrey,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
