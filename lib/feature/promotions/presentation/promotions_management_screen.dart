import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../domain/entities/promotion.dart';
import 'widgets/add_promo_sheet.dart';
import 'widgets/promo_analytics.dart';
import 'widgets/promo_card.dart';

/// Promotions management screen – thin orchestrator that delegates
/// rendering to extracted widgets.
class PromotionsManagementScreen extends StatefulWidget {
  final void Function(String)? onNavigate;
  final VoidCallback? onBack;

  const PromotionsManagementScreen({super.key, this.onNavigate, this.onBack});

  @override
  State<PromotionsManagementScreen> createState() =>
      _PromotionsManagementScreenState();
}

class _PromotionsManagementScreenState
    extends State<PromotionsManagementScreen> {
  final ImagePicker _picker = ImagePicker();

  // Dummy promotions
  final List<Promotion> _promotions = [
    Promotion(
      title: 'Menu déjeuner -15%',
      subtitle: 'Valide du 10/11 au 19/11 - Exclusif VIP',
      dateFrom: DateTime(2025, 11, 10),
      dateTo: DateTime(2025, 11, 19),
      selectedClientType: ClientType.gratuit,
      isOnline: true,
    ),
    Promotion(
      title: 'Café offert',
      subtitle: 'Valide du 01/12 au 31/12 - Tous clients',
      dateFrom: DateTime(2025, 12, 1),
      dateTo: DateTime(2025, 12, 31),
      selectedClientType: ClientType.premium,
      isOnline: false,
    ),
  ];

  // ── actions ────────────────────────────────────────────────────────────────

  Future<void> _showAddPromoSheet() async {
    final result = await showModalBottomSheet<Promotion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddPromoSheet(),
    );
    if (result != null && mounted) {
      setState(() => _promotions.insert(0, result));
    }
  }

  Future<void> _confirmDelete(int index) async {
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
          'Êtes-vous sûr de vouloir supprimer « ${_promotions[index].title} » ?',
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
    if (confirmed == true && mounted) {
      setState(() => _promotions.removeAt(index));
    }
  }

  Future<void> _pickImageForPromo(int index) async {
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
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() {
          _promotions[index] =
              _promotions[index].copyWith(imagePath: picked.path);
        });
      }
    } catch (_) {}
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    _buildAddPromoSection(),
                    if (_promotions.isNotEmpty) _buildPromoList(),
                    const PromoAnalytics(),
                    _buildNotificationsAutoButton(),
                  ],
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
        onTap: _showAddPromoSheet,
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

  // ── promo list ─────────────────────────────────────────────────────────────

  Widget _buildPromoList() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          ..._promotions.asMap().entries.map((entry) {
            final index = entry.key;
            final promo = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PromoCard(
                promo: promo,
                onToggle: (v) => setState(
                  () => _promotions[index] = promo.copyWith(isOnline: v),
                ),
                onDelete: () => _confirmDelete(index),
                onPickImage: () => _pickImageForPromo(index),
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
