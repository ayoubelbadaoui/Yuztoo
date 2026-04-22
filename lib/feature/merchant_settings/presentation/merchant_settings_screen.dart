import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/logout_confirm_dialog.dart';
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
  bool? _messageConciergerie;
  bool? _fidelite;
  bool? _notificationsAuto;
  bool? _galerie;

  /// Whether we've seeded local state from the Firestore merchant doc.
  bool _initialised = false;

  void _seed(
    bool messaging,
    bool loyalty,
    bool notifications,
    bool galerie,
  ) {
    if (_initialised) return;
    _initialised = true;
    _messageConciergerie = messaging;
    _fidelite = loyalty;
    _notificationsAuto = notifications;
    _galerie = galerie;
  }

  Future<void> _toggle({
    bool? messagingEnabled,
    bool? notificationsAutoEnabled,
    bool? galerieEnabled,
    bool? loyaltyEnabled,
  }) async {
    final merchantId = ref.read(currentMerchantIdProvider);
    if (merchantId == null) return;
    final result = await ref.read(updateServiceSettingsProvider).call(
          merchantId: merchantId,
          messagingEnabled: messagingEnabled,
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

  void _setMessageConciergerie(bool v) {
    setState(() => _messageConciergerie = v);
    _toggle(messagingEnabled: v);
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

  @override
  Widget build(BuildContext context) => _buildMerchantSettingsBody(context);
}
