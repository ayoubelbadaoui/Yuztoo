import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import 'widgets/fidelite_info_box.dart';
import 'widgets/reward_row.dart';

/// "E-Fidélité" screen – loyalty rewards configuration.
///
/// Thin orchestrator that composes extracted widgets:
///  • [RewardRow] – toggle + label + gold badge (reused 8×)
///  • [FideliteInfoBox] – summary info card
class EFideliteScreen extends StatefulWidget {
  const EFideliteScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<EFideliteScreen> createState() => _EFideliteScreenState();
}

class _EFideliteScreenState extends State<EFideliteScreen> {
  // ── Récompense offerte toggles ──
  bool _bonAchat = true;
  bool _remise = true;
  bool _produitOffert = true;
  bool _pointsFidelite = true;

  // ── Limite toggles ──
  bool _validite = true;
  bool _minimumPassage = true;

  // ── Activer la récompense toggles ──
  bool _nombrePassage = true;
  bool _cumulAchat = true;

  // ── Bottom toggles ──
  bool _exigerMontant = true;
  bool _validationAuto = false;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section 1: Récompense offerte ──
                    _sectionTitle('Récompense offerte:'),
                    RewardRow(
                      label: 'Bon d\'achat',
                      badge: '10€',
                      value: _bonAchat,
                      onChanged: (v) => setState(() => _bonAchat = v),
                    ),
                    RewardRow(
                      label: 'Remise sur prochain achat',
                      badge: '10%',
                      value: _remise,
                      onChanged: (v) => setState(() => _remise = v),
                    ),
                    RewardRow(
                      label: 'Produit offert',
                      badge: 'Pizza',
                      value: _produitOffert,
                      onChanged: (v) => setState(() => _produitOffert = v),
                    ),
                    RewardRow(
                      label: 'Points Fidélité',
                      badge: '10€ + 1p',
                      value: _pointsFidelite,
                      onChanged: (v) => setState(() => _pointsFidelite = v),
                    ),

                    // ── Section 2: Limite ──
                    _sectionTitle('Limite'),
                    RewardRow(
                      label: 'Validité',
                      badge: '1 an',
                      value: _validite,
                      onChanged: (v) => setState(() => _validite = v),
                    ),
                    RewardRow(
                      label: 'Minimum par passage',
                      badge: '50€',
                      value: _minimumPassage,
                      onChanged: (v) => setState(() => _minimumPassage = v),
                    ),

                    // ── Section 3: Activer la récompense en fonction ──
                    _sectionTitle('Activer la récompense en fonction'),
                    RewardRow(
                      label: 'Nombre de passage',
                      badge: '1 an',
                      value: _nombrePassage,
                      onChanged: (v) => setState(() => _nombrePassage = v),
                    ),
                    RewardRow(
                      label: 'Cumul d\'achat',
                      badge: '100€',
                      value: _cumulAchat,
                      onChanged: (v) => setState(() => _cumulAchat = v),
                    ),

                    // ── Info box ──
                    const FideliteInfoBox(),

                    // ── Bottom toggles ──
                    _buildBottomToggles(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── header with back button ───────────────────────────────────────────────

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
          child: Row(
            children: [
              GestureDetector(
                onTap: () => widget.onBack?.call(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: MerchantColors.gold, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back_ios_new,
                        color: MerchantColors.gold, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'E-Fidélité',
                style: GoogleFonts.outfit(
                  fontSize: 18,
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

  // ── section title ─────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── bottom toggles ────────────────────────────────────────────────────────

  Widget _buildBottomToggles() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _bottomToggle(
            label: 'Exigez le montant d\'achat par passage',
            value: _exigerMontant,
            onChanged: (v) => setState(() => _exigerMontant = v),
          ),
          const SizedBox(height: 12),
          _bottomToggle(
            label: 'Validation passage automatique',
            value: _validationAuto,
            onChanged: (v) => setState(() => _validationAuto = v),
          ),
        ],
      ),
    );
  }

  Widget _bottomToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: value ? MerchantColors.gold : const Color(0xFF6B5B4F),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

