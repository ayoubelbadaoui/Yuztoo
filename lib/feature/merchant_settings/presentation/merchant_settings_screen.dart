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

  void _setMessageConciergerie(bool v) =>
      setState(() => _messageConciergerie = v);

  void _setFidelite(bool v) => setState(() => _fidelite = v);

  void _setNotificationsAuto(bool v) =>
      setState(() => _notificationsAuto = v);

  void _setGalerie(bool v) => setState(() => _galerie = v);

  @override
  Widget build(BuildContext context) => _buildMerchantSettingsBody(context);
}
