import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/logout_confirm_dialog.dart';
import '../../auth/core/application/providers.dart';
import 'widgets/settings_preferences_section.dart';
import 'widgets/settings_services_section.dart';

/// "Paramètres Pro" screen – thin orchestrator.
///
/// Delegates UI to:
///  • [SettingsPreferencesSection] – account preferences items
///  • [SettingsServicesSection]    – service toggles
class MerchantSettingsScreen extends ConsumerStatefulWidget {
  const MerchantSettingsScreen({super.key, this.onNavigate});

  final ValueChanged<String>? onNavigate;

  @override
  ConsumerState<MerchantSettingsScreen> createState() =>
      _MerchantSettingsScreenState();
}

class _MerchantSettingsScreenState
    extends ConsumerState<MerchantSettingsScreen> {
  bool _messageConciergerie = true;
  bool _fidelite = true;
  bool _notificationsAuto = true;
  bool _galerie = true;

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
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                ),
                child: Column(
                  children: [
                    _buildDescriptionSection(),
                    SettingsPreferencesSection(
                      onNavigate: widget.onNavigate,
                    ),
                    _buildInfoBox(),
                    SettingsServicesSection(
                      services: [
                        ServiceToggle(
                          icon: Icons.chat_bubble_outline,
                          label: 'Message conciergerie',
                          value: _messageConciergerie,
                          onChanged: (v) =>
                              setState(() => _messageConciergerie = v),
                        ),
                        ServiceToggle(
                          icon: Icons.favorite_outline,
                          label: 'Fidélité',
                          value: _fidelite,
                          onChanged: (v) => setState(() => _fidelite = v),
                          onTap: () =>
                              widget.onNavigate?.call('e-fidelite'),
                        ),
                        ServiceToggle(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications automatique',
                          value: _notificationsAuto,
                          onChanged: (v) =>
                              setState(() => _notificationsAuto = v),
                        ),
                        ServiceToggle(
                          icon: Icons.image_outlined,
                          label: 'Galerie',
                          value: _galerie,
                          onChanged: (v) => setState(() => _galerie = v),
                        ),
                      ],
                    ),
                    _buildLogoutSection(),
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
              'Paramètres Pro',
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

  // ── description ────────────────────────────────────────────────────────────

  Widget _buildDescriptionSection() {
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
      child: Center(
        child: Text(
          'Gérez ici tous les paramètres de l\'application',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: MerchantColors.textLightGrey,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  // ── info box ───────────────────────────────────────────────────────────────

  Widget _buildInfoBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MerchantColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Text(
          'Gardez le contrôle sur vos données et activez vos fonctionnalités préférés.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: MerchantColors.textLightGrey,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  // ── logout ─────────────────────────────────────────────────────────────────

  Widget _buildLogoutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm =
                    await showLogoutConfirmationDialog(context);
                if (confirm && mounted) {
                  await ref
                      .read(authControllerProvider.notifier)
                      .signOut();
                }
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: Text(
                'Se déconnecter',
                style: GoogleFonts.outfit(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Version 1.0.0',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
