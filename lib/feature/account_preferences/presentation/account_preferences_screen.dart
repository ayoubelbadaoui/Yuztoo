import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../../../core/shared/constants/merchant_colors.dart';
import '../../storefront/application/providers.dart' as storefront_providers;
import 'widgets/cities_section.dart';
import 'widgets/profile_avatar_section.dart';
import 'widgets/yuztoo_card_box.dart';

/// "Profil" / account preferences screen.
/// All data from Firestore/auth: profile, completion %, cities.
class AccountPreferencesScreen extends ConsumerStatefulWidget {
  const AccountPreferencesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<AccountPreferencesScreen> createState() =>
      _AccountPreferencesScreenState();
}

class _AccountPreferencesScreenState extends ConsumerState<AccountPreferencesScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(auth_providers.authStateProvider);
    final storefrontAsync = ref.watch(storefront_providers.storefrontProvider);
    final isMerchant = authState is Authenticated &&
        authState.user.role == 'merchant';

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
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const ProfileAvatarSection(),
                    _buildConnectionsSection(0),
                    const CitiesSection(),
                    const YuztooCardBox(),
                    _buildCompletionSection(storefrontAsync.valueOrNull?.profileCompletionPercentage ?? 0),
                    _buildInfoSection(),
                    if (!isMerchant) _buildCreateAccountButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
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
                'Profil',
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

  // ── connections section ───────────────────────────────────────────────────

  Widget _buildConnectionsSection(int partnerCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Vous êtes connecté à\n',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
              ),
            ),
            TextSpan(
              text: partnerCount == 0
                  ? 'Aucun partenaire pour l\'instant'
                  : '$partnerCount professionnel${partnerCount > 1 ? 's' : ''} partenaire${partnerCount > 1 ? 's' : ''} Yuztoo',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MerchantColors.gold,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── completion section ────────────────────────────────────────────────────

  Widget _buildCompletionSection(int percentage) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profil complété à',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: MerchantColors.gold,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$percentage%',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MerchantColors.darkOverlay,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── info text ─────────────────────────────────────────────────────────────

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text:
                  'Indépendant, artisan, commerçant, artiste ou association - '
                  'Restez connecté à vos clients et membres. Yuztoo est ',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textLightGrey,
                height: 1.6,
              ),
            ),
            TextSpan(
              text: 'gratuit pour Eux pour Vous',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MerchantColors.gold,
                height: 1.6,
              ),
            ),
            TextSpan(
              text: '.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textLightGrey,
                height: 1.6,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── create account CTA ────────────────────────────────────────────────────

  Widget _buildCreateAccountButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Placeholder – create pro account action
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: MerchantColors.gold,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          child: Text(
            'Créer un compte pro',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

