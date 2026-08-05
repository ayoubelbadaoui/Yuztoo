import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/config/vitrine_qr_config.dart';
import '../../../core/debug/nfc_debug_flags.dart';
import '../../../core/debug/nfc_debug_ui_helpers.dart';
import '../../../core/infrastructure/nfc_service.dart';
import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/snackbar.dart';
import 'widgets/nfc_debug_emulator_sheet.dart';

part 'qr_scanner_screen.part.dart';

/// Debug NFC/scan tools. Also via `--dart-define=SHOW_NFC_DEBUG=true` or
/// `SHOW_SCAN_SIMULATOR=true` on Release builds from Xcode.
const bool kShowQrScanSimulator = kNfcDebugEnabled;

/// Client scan tab — NFC by default; QR available via toggle.
class QRScannerScreen extends ConsumerStatefulWidget {
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
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen>
    with WidgetsBindingObserver {
  /// [autoStart] must stay false: we mount/unmount [MobileScanner] when
  /// toggling NFC ↔ QR, and a concurrent auto-start races [start]/[stop]
  /// on Android (black preview on the second open).
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  DateTime? _lastScanTime;
  static const _scanCooldown = Duration(seconds: 2);

  bool _nfcMode = true;
  bool _nfcScanning = false;
  bool _cameraStarting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _nfcMode) _startNfcScan();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Camera is only live in QR mode; skip while NFC overlay is showing.
    if (_nfcMode) return;
    if (!_controller.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_startCamera());
      case AppLifecycleState.inactive:
        unawaited(_stopCamera());
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_nfcScanning) {
      unawaited(NfcService.cancelActiveSession());
    }
    unawaited(_disposeCamera());
    super.dispose();
  }

  Future<void> _disposeCamera() async {
    try {
      await _controller.stop();
    } catch (_) {
      // Already stopped / never started.
    }
    await _controller.dispose();
  }

  Future<void> _startCamera() async {
    if (_nfcMode || _cameraStarting || !mounted) return;
    if (_controller.value.isRunning) return;
    _cameraStarting = true;
    try {
      await _controller.start();
    } catch (_) {
      // Permission denial / already starting — errorBuilder handles UI.
    } finally {
      _cameraStarting = false;
    }
  }

  Future<void> _stopCamera() async {
    if (!_controller.value.isRunning) return;
    try {
      await _controller.stop();
    } catch (_) {
      // Already stopped.
    }
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
            style: merchantSnackBarTextOnDark(),
          ),
          backgroundColor: MerchantColors.navyCard,
        ),
      );
      return;
    }

    _completeVitrineScan(merchantId);
  }

  /// Same path as a real QR/NFC hit (vitrine + optional passage sheet).
  void _completeVitrineScan(String merchantId) {
    final id = merchantId.trim();
    if (id.isEmpty) return;
    HapticFeedback.mediumImpact();
    // Release the camera before navigating away so the next open isn't blank.
    if (!_nfcMode) {
      unawaited(_stopCamera());
    }
    widget.onVitrineMerchantFound(id);
  }

  Future<void> _openDebugEmulator({int initialTabIndex = 0}) async {
    assert(kShowQrScanSimulator);
    await showNfcDebugEmulatorSheet(
      context,
      onNavigateToVitrine: _completeVitrineScan,
      initialTabIndex: initialTabIndex,
    );
  }

  Future<void> _startNfcScan() async {
    if (_nfcScanning) return;
    final blocked = await NfcService.unavailableReason();
    if (!mounted) return;
    if (blocked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            blocked,
            style: merchantSnackBarTextOnDark(),
          ),
          backgroundColor: MerchantColors.navyCard,
        ),
      );
      return;
    }
    setState(() => _nfcScanning = true);
    final result = await NfcService.readVitrineMerchantId(
      alertMessage: 'Approchez votre téléphone du badge Yuztoo',
    );
    if (!mounted) return;
    setState(() => _nfcScanning = false);
    applyNfcReadResult(
      context,
      result,
      onValidMerchantId: _completeVitrineScan,
    );
  }

  Future<void> _toggleMode() async {
    if (_nfcMode) {
      // NFC → QR: cancel NFC, mount scanner, then start after the frame.
      if (_nfcScanning) {
        await NfcService.cancelActiveSession();
        if (!mounted) return;
        setState(() => _nfcScanning = false);
      }
      setState(() => _nfcMode = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_nfcMode) {
          unawaited(_startCamera());
        }
      });
      return;
    }

    // QR → NFC: stop camera before removing [MobileScanner] from the tree.
    await _stopCamera();
    if (!mounted) return;
    setState(() => _nfcMode = true);
    unawaited(_startNfcScan());
  }

  Future<void> _retryCamera() async {
    await _stopCamera();
    if (!mounted) return;
    await _startCamera();
  }

  @override
  Widget build(BuildContext context) => _buildQrScannerUi(context);
}
