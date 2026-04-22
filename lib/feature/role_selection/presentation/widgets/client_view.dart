import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'role_selection_colors.dart';
import 'qr_pattern_painter.dart';
import '../../../../l10n/app_localizations.dart';

part 'client_view.part.dart';

/// Client view widget for role selection screen
class ClientView extends StatefulWidget {
  const ClientView({
    super.key,
    required this.isScanning,
    required this.onScan,
    required this.onCreateAccount,
    this.onGuestDiscover,
  });

  final bool isScanning;
  final VoidCallback onScan;
  final VoidCallback onCreateAccount;
  /// Optional: browse merchants without creating an account.
  final VoidCallback? onGuestDiscover;

  @override
  State<ClientView> createState() => _ClientViewState();
}

class _ClientViewState extends State<ClientView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildClientViewBody(context);
}

