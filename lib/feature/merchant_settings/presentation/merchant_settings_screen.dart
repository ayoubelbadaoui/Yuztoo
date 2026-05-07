import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/logout_confirm_dialog.dart';
import '../../legal/domain/legal_document.dart';
import '../../legal/presentation/legal_document_screen.dart';
import '../application/providers.dart';
import 'widgets/settings_preferences_section.dart';
import 'widgets/settings_services_section.dart';

part 'merchant_settings_screen.part.dart';

/// "Paramètres Pro" screen – thin orchestrator.
///
/// Delegates UI to:
///  • [SettingsPreferencesSection] – account preferences items
///  • [SettingsServicesSection]    – service toggles (persisted to Firestore)
class MerchantSettingsScreen extends ConsumerStatefulWidget {
  const MerchantSettingsScreen({super.key, this.onNavigate});

  final ValueChanged<String>? onNavigate;

  @override
  ConsumerState<MerchantSettingsScreen> createState() =>
      _MerchantSettingsScreenState();
}

class _MerchantSettingsScreenState
    extends ConsumerState<MerchantSettingsScreen> {
  bool? _fidelite;
  bool? _notificationsAuto;
  bool? _galerie;

  /// Whether we've seeded local state from the Firestore merchant doc.
  bool _initialised = false;

  void _seed(
    bool loyalty,
    bool notifications,
    bool galerie,
  ) {
    if (_initialised) return;
    _initialised = true;
    _fidelite = loyalty;
    _notificationsAuto = notifications;
    _galerie = galerie;
  }

  Future<void> _toggle({
    bool? notificationsAutoEnabled,
    bool? galerieEnabled,
    bool? loyaltyEnabled,
  }) async {
    final merchantId = ref.read(currentMerchantIdProvider);
    if (merchantId == null) return;
    final result = await ref.read(updateServiceSettingsProvider).call(
          merchantId: merchantId,
          notificationsAutoEnabled: notificationsAutoEnabled,
          galerieEnabled: galerieEnabled,
          loyaltyEnabled: loyaltyEnabled,
        );
    if (!mounted) return;
    result.fold(
      (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(f.message, style: GoogleFonts.outfit()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[700],
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Paramètre mis à jour',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: MerchantColors.gold,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  void _setFidelite(bool v) {
    setState(() => _fidelite = v);
    _toggle(loyaltyEnabled: v);
  }

  void _setNotificationsAuto(bool v) {
    setState(() => _notificationsAuto = v);
    _toggle(notificationsAutoEnabled: v);
  }

  void _setGalerie(bool v) {
    setState(() => _galerie = v);
    _toggle(galerieEnabled: v);
  }

  // One-time info popup per app session.
  static bool _hasShownInfo = false;

  @override
  void initState() {
    super.initState();
    if (!_hasShownInfo) {
      _hasShownInfo = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showInfoPopup();
      });
    }
  }

  void _showInfoPopup() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: MerchantColors.gold
                  .withValues(alpha: MerchantColors.goldBorderStronger),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MerchantColors.gold.withValues(alpha: 0.15),
                  border: Border.all(color: MerchantColors.gold, width: 2),
                ),
                child: const Icon(Icons.settings_rounded,
                    color: MerchantColors.gold, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                'Gardez le contrôle',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Gérez vos données et activez ou désactivez vos fonctionnalités à tout moment depuis cette page.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: MerchantColors.textLightGrey,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Compris !',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MerchantColors.darkOverlay,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildMerchantSettingsBody(context);
}
