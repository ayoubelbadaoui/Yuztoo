part of 'client_view.dart';

extension _ClientViewUi on _ClientViewState {
  Widget _buildClientViewBody(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: RoleSelectionColors.primaryGold.withValues(alpha: 0.35),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(20),
        color: RoleSelectionColors.bgDark2.withValues(alpha: 0.7),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                      color: RoleSelectionColors.primaryGold.withValues(
                        alpha: 0.25 * _pulseAnimation.value,
                      ),
                      blurRadius: 20 * _pulseAnimation.value,
                      spreadRadius: 3 * _pulseAnimation.value,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: RoleSelectionColors.primaryGold.withValues(
                        alpha: 0.4 + (0.15 * _pulseAnimation.value),
                      ),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    color: RoleSelectionColors.bgDark1.withValues(alpha: 0.6),
                  ),
                  child: const Center(
                    child: CustomPaint(
                      size: Size(85, 85),
                      painter: QrPatternPainter(
                        color: RoleSelectionColors.primaryGold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${AppLocalizations.of(context)!.scanQRCode} ',
                  style: const TextStyle(
                    fontSize: 13,
                    color: RoleSelectionColors.textLight,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: AppLocalizations.of(context)!.qrCode,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: RoleSelectionColors.primaryGold,
                    height: 1.4,
                  ),
                ),
                const TextSpan(
                  text: ' ou la ',
                  style: TextStyle(
                    fontSize: 13,
                    color: RoleSelectionColors.textLight,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const TextSpan(
                  text: 'plaque',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: RoleSelectionColors.primaryGold,
                    height: 1.4,
                  ),
                ),
                const TextSpan(
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
          Text(
            AppLocalizations.of(context)!.addToYuztoo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: RoleSelectionColors.textGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      shadowColor: RoleSelectionColors.primaryGold
                          .withValues(alpha: 0.2),
                      elevation: widget.isScanning ? 8 : 6,
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
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.isScanning
                                ? AppLocalizations.of(context)!.scanning
                                : AppLocalizations.of(context)!.startScan,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: RoleSelectionColors.bgDark1,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                    child: const Text(
                      'Créer un compte',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: RoleSelectionColors.primaryGold,
                        letterSpacing: 0.2,
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
