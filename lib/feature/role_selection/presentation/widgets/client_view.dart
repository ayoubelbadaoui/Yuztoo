import 'package:flutter/material.dart';
import 'role_selection_colors.dart';
import 'qr_pattern_painter.dart';

/// Client view widget for role selection screen
class ClientView extends StatefulWidget {
  const ClientView({
    super.key,
    required this.isScanning,
    required this.onScan,
  });

  final bool isScanning;
  final VoidCallback onScan;

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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        border: Border.all(
          color: RoleSelectionColors.primaryGold.withOpacity(0.35),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(20),
        color: RoleSelectionColors.bgDark2.withOpacity(0.7),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR Code Box with animation - more compact
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: RoleSelectionColors.primaryGold.withOpacity(
                        0.25 * _pulseAnimation.value,
                      ),
                      blurRadius: 20 * _pulseAnimation.value,
                      spreadRadius: 3 * _pulseAnimation.value,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: RoleSelectionColors.primaryGold.withOpacity(
                        0.4 + (0.15 * _pulseAnimation.value),
                      ),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    color: RoleSelectionColors.bgDark1.withOpacity(0.6),
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(85, 85),
                      painter: QrPatternPainter(
                        color: RoleSelectionColors.primaryGold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Description Text - more compact
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Scanne le ',
                  style: TextStyle(
                    fontSize: 13,
                    color: RoleSelectionColors.textLight,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: 'QR code',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: RoleSelectionColors.primaryGold,
                    height: 1.4,
                  ),
                ),
                TextSpan(
                  text: ' ou la ',
                  style: TextStyle(
                    fontSize: 13,
                    color: RoleSelectionColors.textLight,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: 'plaque',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: RoleSelectionColors.primaryGold,
                    height: 1.4,
                  ),
                ),
                TextSpan(
                  text: ' de ton commerce',
                  style: TextStyle(
                    fontSize: 13,
                    color: RoleSelectionColors.textLight,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Ajoute-le à ton carnet Yuztoo\net reçois ses infos utiles',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: RoleSelectionColors.textGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Scan Button - more compact
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 48,
            decoration: widget.isScanning
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: RoleSelectionColors.primaryGold.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  )
                : null,
            child: ElevatedButton.icon(
              onPressed: widget.isScanning ? null : widget.onScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: RoleSelectionColors.primaryGold,
                disabledBackgroundColor:
                    RoleSelectionColors.primaryGold.withOpacity(0.75),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: RoleSelectionColors.primaryGold.withOpacity(0.2),
                elevation: widget.isScanning ? 8 : 6,
              ),
              icon: widget.isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          RoleSelectionColors.bgDark1,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: RoleSelectionColors.bgDark1,
                      size: 20,
                    ),
              label: Text(
                widget.isScanning ? 'Scan en cours...' : 'Lancer le scan',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: RoleSelectionColors.bgDark1,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

