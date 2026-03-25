import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/config/vitrine_qr_config.dart';
import '../../../core/shared/constants/merchant_colors.dart';

/// QR Scanner tab – camera opens immediately, live scan with design overlay.
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({
    super.key,
    required this.onBack,
    required this.onVitrineMerchantFound,
  });

  static String get path => '/qr-scanner';

  final VoidCallback onBack;

  /// Called when the QR encodes a Yuztoo vitrine URL for a commerce ([merchantId]).
  final void Function(String merchantId) onVitrineMerchantFound;

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  DateTime? _lastScanTime;
  static const _scanCooldown = Duration(seconds: 2);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final now = DateTime.now();
    if (_lastScanTime != null && now.difference(_lastScanTime!) < _scanCooldown) {
      return;
    }
    _lastScanTime = now;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    final merchantId = VitrineQrConfig.tryParseMerchantId(raw);
    if (merchantId == null || merchantId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ce QR code ne correspond pas à une vitrine Yuztoo.',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: MerchantColors.navyCard,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    widget.onVitrineMerchantFound(merchantId);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgHeader,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Live camera – fills screen
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) => _buildCameraError(context, error),
              placeholderBuilder: (context, child) => _buildCameraPlaceholder(context),
            ),
            // Design overlay: header + scan frame + instructions
            _buildOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPlaceholder(BuildContext context) {
    return Container(
      color: MerchantColors.bgMain,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
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
            Icon(Icons.camera_alt_outlined, size: 64, color: MerchantColors.gold.withValues(alpha: 0.6)),
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
              error.errorDetails?.message ?? 'Vérifiez les autorisations dans Réglages.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textLightGrey,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => _controller.start(),
              icon: Icon(Icons.refresh, color: MerchantColors.gold, size: 20),
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
        // Header
        Container(
          color: Colors.black54,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: Icon(Icons.arrow_back, color: MerchantColors.gold, size: 26),
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
                    child: Icon(Icons.qr_code_scanner, color: MerchantColors.gold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Scan',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: MerchantColors.textWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Scan frame overlay (dark mask + gold corners) + centered instructions
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
                  // Dark mask with cutout
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
                  // Hint text above scan area
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
                  // Bottom bar: hint + test button
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: padding.bottom + 80 + 16,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Le QR code est à la caisse ou à l\'entrée',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: MerchantColors.textLightGrey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                final demo = VitrineQrConfig.uriStringForMerchant('demo');
                                final id = VitrineQrConfig.tryParseMerchantId(demo);
                                if (id != null) {
                                  widget.onVitrineMerchantFound(id);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MerchantColors.gold,
                                side: const BorderSide(color: MerchantColors.gold, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.qr_code_scanner, size: 20),
                              label: Text(
                                'Scanner un code de test',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Paints a dark overlay with a clear rounded-rect cutout and gold corners.
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
    // Full mask
    final maskPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRRect(scanRect);
    final path = Path.combine(PathOperation.difference, maskPath, holePath);
    canvas.drawPath(path, Paint()..color = maskColor);

    // Gold corners
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
