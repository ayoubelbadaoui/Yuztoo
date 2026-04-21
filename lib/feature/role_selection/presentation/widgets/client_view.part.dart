part of 'client_view.dart';

extension _ClientViewUi on _ClientViewState {
  Widget _buildClientViewBody(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        border: Border.all(
          color: RoleSelectionColors.primaryGold.withValues(alpha: 0.25),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
        color: RoleSelectionColors.bgDark2.withValues(alpha: 0.6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR code preview with animated gold glow
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: RoleSelectionColors.primaryGold.withValues(
                        alpha: 0.22 * _pulseAnimation.value,
                      ),
                      blurRadius: 18 * _pulseAnimation.value,
                      spreadRadius: 2 * _pulseAnimation.value,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: RoleSelectionColors.primaryGold.withValues(
                        alpha: 0.35 + (0.15 * _pulseAnimation.value),
                      ),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    color: RoleSelectionColors.bgDark1.withValues(alpha: 0.6),
                  ),
                  child: const Center(
                    child: CustomPaint(
                      size: Size(80, 80),
                      painter: QrPatternPainter(
                        color: RoleSelectionColors.primaryGold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Instruction text — fixed copy: "d'un commerce" not "de ton commerce"
          Text.rich(
            TextSpan(
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: RoleSelectionColors.textLight,
                height: 1.5,
              ),
              children: [
                TextSpan(text: AppLocalizations.of(context)!.scanQRCode + ' '),
                TextSpan(
                  text: 'QR Code',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: RoleSelectionColors.primaryGold,
                    height: 1.5,
                  ),
                ),
                const TextSpan(text: " ou la carte d'un commerce"),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.addToYuztoo,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: RoleSelectionColors.textGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // CTAs
          Row(
            children: [
              // Primary: Scan
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  decoration: widget.isScanning
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: RoleSelectionColors.primaryGold
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        )
                      : null,
                  child: ElevatedButton(
                    onPressed: widget.isScanning ? null : widget.onScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RoleSelectionColors.primaryGold,
                      disabledBackgroundColor: RoleSelectionColors.primaryGold
                          .withValues(alpha: 0.75),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: widget.isScanning ? 8 : 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isScanning)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                RoleSelectionColors.bgDark1,
                              ),
                            ),
                          )
                        else
                          const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: RoleSelectionColors.bgDark1,
                            size: 20,
                          ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.isScanning
                                ? AppLocalizations.of(context)!.scanning
                                : AppLocalizations.of(context)!.startScan,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: RoleSelectionColors.bgDark1,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Secondary: Create account
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: widget.onCreateAccount,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      side: const BorderSide(
                        color: RoleSelectionColors.primaryGold,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Créer un compte',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: RoleSelectionColors.primaryGold,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
