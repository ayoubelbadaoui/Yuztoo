import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/config/vitrine_qr_config.dart';
import '../../../core/infrastructure/nfc_service.dart';
import '../../../core/shared/constants/merchant_colors.dart';

part 'qr_scanner_screen.part.dart';

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

  bool _nfcMode = false;
  bool _nfcScanning = false;

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

  Future<void> _startNfcScan() async {
    if (_nfcScanning) return;
    final available = await NfcService.isAvailable();
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('NFC non disponible sur cet appareil.',
              style: GoogleFonts.outfit()),
          backgroundColor: MerchantColors.navyCard,
        ),
      );
      return;
    }
    setState(() => _nfcScanning = true);
    final result = await NfcService.readVitrineMerchantId(
      alertMessage: 'Approchez votre téléphone de celui du commerçant',
    );
    if (!mounted) return;
    setState(() => _nfcScanning = false);
    switch (result) {
      case NfcSuccess(:final merchantId):
        if (merchantId != null && merchantId.isNotEmpty) {
          HapticFeedback.mediumImpact();
          widget.onVitrineMerchantFound(merchantId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aucune vitrine Yuztoo détectée par NFC.',
                  style: GoogleFonts.outfit()),
              backgroundColor: MerchantColors.navyCard,
            ),
          );
        }
      case NfcUnavailable():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NFC non disponible.', style: GoogleFonts.outfit()),
            backgroundColor: MerchantColors.navyCard,
          ),
        );
      case NfcError(:final message):
        if (message != 'Lecture annulée.') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message, style: GoogleFonts.outfit()),
              backgroundColor: MerchantColors.navyCard,
            ),
          );
        }
    }
  }

  void _toggleMode() {
    setState(() {
      _nfcMode = !_nfcMode;
      if (_nfcMode) {
        _controller.stop();
      } else {
        _controller.start();
      }
    });
    if (_nfcMode) _startNfcScan();
  }

  @override
  Widget build(BuildContext context) => _buildQrScannerUi(context);
}
