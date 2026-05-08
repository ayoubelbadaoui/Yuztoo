part of 'qr_scanner_screen.dart';

extension _QRScannerScreenUi on _QRScannerScreenState {
  Widget _buildQrScannerUi(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (!_nfcMode) ...[
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error, child) =>
                    _buildCameraError(context, error),
                placeholderBuilder: (context, child) =>
                    _buildCameraPlaceholder(context),
              ),
            ] else
              _buildNfcOverlay(context),
            _buildOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNfcOverlay(BuildContext context) {
    return Container(
      color: MerchantColors.bgMain,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantColors.gold.withValues(alpha: _nfcScanning ? 0.15 : 0.08),
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: _nfcScanning ? 0.8 : 0.4),
                  width: 2,
                ),
              ),
              child: _nfcScanning
                  ? const Center(
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: MerchantColors.gold,
                        ),
                      ),
                    )
                  : const Icon(Icons.nfc_rounded,
                      color: MerchantColors.gold, size: 56),
            ),
            const SizedBox(height: 24),
            Text(
              // Phone-to-phone NFC: the merchant holds their phone in
              // "show" mode, the client taps theirs against it. Same
              // gesture as scanning a QR code in the merchant's hand,
              // just over NFC instead of camera. Plaque-tap copy is
              // gone because the plaque-programming UI is hidden
              // (see _kEnableNfcPlaquePrograming in merchant_qr_screen).
              _nfcScanning
                  ? 'Connectez les deux téléphones\npar NFC'
                  : 'Mode NFC',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _nfcScanning
                  ? 'Approchez votre téléphone de celui du commerçant'
                  : 'Appuyez sur le bouton NFC pour démarrer',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textGrey,
                height: 1.4,
              ),
            ),
            if (!_nfcScanning) ...[
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _startNfcScan,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: MerchantColors.gold.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.nfc_rounded,
                          color: MerchantColors.bgMain, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Démarrer la lecture NFC',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: MerchantColors.bgMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPlaceholder(BuildContext context) {    return Container(
      color: MerchantColors.bgMain,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: MerchantColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ouverture de la caméra...',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: MerchantColors.textLightGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraError(BuildContext context, MobileScannerException error) {
    return Container(
      color: MerchantColors.bgMain,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined,
                size: 64, color: MerchantColors.gold.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'Impossible d\'accéder à la caméra',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MerchantColors.textWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.errorDetails?.message ??
                  'Vérifiez les autorisations dans Réglages.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textLightGrey,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => _controller.start(),
              icon: const Icon(Icons.refresh,
                  color: MerchantColors.gold, size: 20),
              label: Text(
                'Réessayer',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.gold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Column(
      children: [
        Container(
          color: Colors.black54,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: MerchantColors.gold, size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: MerchantColors.gold, width: 2),
                      color: MerchantColors.gold.withValues(alpha: 0.15),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _nfcMode ? Icons.nfc_rounded : Icons.qr_code_scanner,
                      color: MerchantColors.gold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _nfcMode ? 'NFC' : 'Scan QR',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: MerchantColors.textWhite,
                      ),
                    ),
                  ),
                  // QR ↔ NFC toggle
                  GestureDetector(
                    onTap: _toggleMode,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: MerchantColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: MerchantColors.gold.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _nfcMode
                                ? Icons.qr_code_scanner
                                : Icons.nfc_rounded,
                            color: MerchantColors.gold,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _nfcMode ? 'QR' : 'NFC',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: MerchantColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
        if (!_nfcMode)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final side = (width < height ? width : height) * 0.72;
                final left = (width - side) / 2;
                final top = (height - side) / 2;
                final scanRect = RRect.fromRectAndRadius(
                  Rect.fromLTWH(left, top, side, side),
                  const Radius.circular(20),
                );

                return Stack(
                  children: [
                    CustomPaint(
                      size: Size(width, height),
                      painter: _ScanOverlayPainter(
                        scanRect: scanRect,
                        maskColor: Colors.black54,
                        cornerColor: MerchantColors.gold,
                        cornerStrokeWidth: 4,
                        cornerLength: 36,
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      top: top - 56,
                      child: Text(
                        'Positionnez le QR code dans le cadre',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: MerchantColors.textWhite,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: padding.bottom + 80 + 16,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Le QR code est à la caisse ou à l\'entrée',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: MerchantColors.textLightGrey,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        else
          const Expanded(child: SizedBox()),
      ],
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  _ScanOverlayPainter({
    required this.scanRect,
    required this.maskColor,
    required this.cornerColor,
    this.cornerStrokeWidth = 4,
    this.cornerLength = 36,
  });

  final RRect scanRect;
  final Color maskColor;
  final Color cornerColor;
  final double cornerStrokeWidth;
  final double cornerLength;

  @override
  void paint(Canvas canvas, Size size) {
    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRRect(scanRect);
    final path = Path.combine(PathOperation.difference, maskPath, holePath);
    canvas.drawPath(path, Paint()..color = maskColor);

    final paint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerStrokeWidth;

    final r = scanRect.trRadius.x;
    final l = cornerLength;

    final tl = Offset(scanRect.left, scanRect.top);
    canvas.drawPath(_cornerPath(tl, r, l, _Corner.topLeft), paint);

    final tr = Offset(scanRect.right, scanRect.top);
    canvas.drawPath(_cornerPath(tr, r, l, _Corner.topRight), paint);

    final bl = Offset(scanRect.left, scanRect.bottom);
    canvas.drawPath(_cornerPath(bl, r, l, _Corner.bottomLeft), paint);

    final br = Offset(scanRect.right, scanRect.bottom);
    canvas.drawPath(_cornerPath(br, r, l, _Corner.bottomRight), paint);
  }

  Path _cornerPath(Offset origin, double radius, double length, _Corner corner) {
    final path = Path();
    switch (corner) {
      case _Corner.topLeft:
        path.moveTo(origin.dx + radius, origin.dy);
        path.lineTo(origin.dx + length, origin.dy);
        path.moveTo(origin.dx, origin.dy + radius);
        path.lineTo(origin.dx, origin.dy + length);
        break;
      case _Corner.topRight:
        path.moveTo(origin.dx - radius, origin.dy);
        path.lineTo(origin.dx - length, origin.dy);
        path.moveTo(origin.dx, origin.dy + radius);
        path.lineTo(origin.dx, origin.dy + length);
        break;
      case _Corner.bottomLeft:
        path.moveTo(origin.dx + radius, origin.dy);
        path.lineTo(origin.dx + length, origin.dy);
        path.moveTo(origin.dx, origin.dy - radius);
        path.lineTo(origin.dx, origin.dy - length);
        break;
      case _Corner.bottomRight:
        path.moveTo(origin.dx - radius, origin.dy);
        path.lineTo(origin.dx - length, origin.dy);
        path.moveTo(origin.dx, origin.dy - radius);
        path.lineTo(origin.dx, origin.dy - length);
        break;
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }
