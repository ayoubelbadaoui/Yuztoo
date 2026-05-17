import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/config/vitrine_qr_config.dart';
import '../../../core/infrastructure/nfc_service.dart';
import '../../merchant/application/providers.dart';

/// NFC plaque programming is Android-only — Apple does not allow third-party
/// apps to write NDEF records to NFC tags from iOS. Reading already works on
/// both platforms (iOS reader entitlement is in place), so clients on any
/// device can tap a badge programmed by an Android merchant or shipped
/// pre-programmed by Yuztoo.
final bool _kEnableNfcPlaquePrograming = Platform.isAndroid;

/// Merchant QR Code screen — real QR backed by the merchant's Firestore ID.
/// Merchants scan this to let clients follow their store.
class MerchantQRCodeScreen extends ConsumerStatefulWidget {
  const MerchantQRCodeScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<MerchantQRCodeScreen> createState() =>
      _MerchantQRCodeScreenState();
}

class _MerchantQRCodeScreenState extends ConsumerState<MerchantQRCodeScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;
  bool _isSharing = false;
  bool _isWritingNfc = false;

  /// Captures the QR widget as PNG bytes.
  Future<Uint8List?> _captureQr() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await _captureQr();
      if (bytes == null) throw Exception('Capture failed');

      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) await Gal.requestAccess(toAlbum: true);
      await Gal.putImageBytes(bytes, album: 'Yuztoo');

      if (mounted) {
        _showSnack('QR code sauvegardé dans la galerie', isSuccess: true);
      }
    } catch (_) {
      if (mounted) _showSnack('Impossible de sauvegarder');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareQr(String merchantName) async {
    setState(() => _isSharing = true);
    try {
      final bytes = await _captureQr();
      if (bytes == null) throw Exception('Capture failed');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/yuztoo_qr.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          subject: 'Mon QR code Yuztoo — $merchantName',
          text: 'Scannez ce code pour suivre $merchantName sur Yuztoo !',
        ),
      );
    } catch (_) {
      if (mounted) _showSnack('Impossible de partager');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _writeNfc(String merchantId) async {
    final available = await NfcService.isAvailable();
    if (!mounted) return;
    if (!available) {
      _showSnack('NFC non disponible sur cet appareil');
      return;
    }
    setState(() => _isWritingNfc = true);
    final result = await NfcService.writeVitrineUrl(merchantId);
    if (!mounted) return;
    setState(() => _isWritingNfc = false);
    switch (result) {
      case NfcSuccess():
        _showSnack('Badge NFC programmé avec succès !', isSuccess: true);
      case NfcUnavailable():
        _showSnack('NFC non disponible sur cet appareil');
      case NfcError(:final message):
        _showSnack(message);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor:
            isSuccess ? const Color(0xFF1B7A4B) : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync = ref.watch(currentMerchantForOwnerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: merchantAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: MerchantColors.gold),
                ),
                error: (_, __) => _buildError(),
                data: (merchant) {
                  if (merchant == null) return _buildError();
                  return _buildBody(merchant.id, merchant.name);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onBack,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: MerchantColors.gold, size: 20),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Center(
                  child: Text(
                    'Mon QR Code',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(String merchantId, String merchantName) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, 32, 24, bottom + 24),
      child: Column(
        children: [
          // ── heading ─────────────────────────────────────────────────
          Text(
            'Code de connexion',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les clients scannent ce code pour rejoindre\nvotre boutique sur Yuztoo',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // ── QR card ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: MerchantColors.navyCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
              ),
              boxShadow: [
                BoxShadow(
                  color: MerchantColors.gold.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                // The RepaintBoundary wraps only the white QR area
                RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: QrImageView(
                      data: VitrineQrConfig.uriStringForMerchant(merchantId),
                      version: QrVersions.auto,
                      size: 220,
                      gapless: true,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0B1F33),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0B1F33),
                      ),
                      embeddedImageStyle: const QrEmbeddedImageStyle(
                        size: Size(40, 40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Merchant name
                Text(
                  merchantName,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                // Short code chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: MerchantColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: MerchantColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    merchantId.length > 12
                        ? 'ID: ${merchantId.substring(0, 12)}…'
                        : 'ID: $merchantId',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MerchantColors.gold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── action buttons ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.download_rounded,
                  label: 'Sauvegarder',
                  isLoading: _isSaving,
                  onTap: _saveToGallery,
                  outlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'Partager',
                  isLoading: _isSharing,
                  onTap: () => _shareQr(merchantName),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── NFC plaque write button (hidden) ────────────────────────
          // Kept in source so flipping _kEnableNfcPlaquePrograming back
          // to true restores the full plaque-programming flow without
          // any rework. The reading side (qr_scanner_screen) keeps
          // working — so plaques already programmed in the wild stay
          // functional even with the merchant button hidden.
          if (_kEnableNfcPlaquePrograming) ...[
            GestureDetector(
              onTap: _isWritingNfc ? null : () => _writeNfc(merchantId),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: MerchantColors.navyCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: MerchantColors.gold
                        .withValues(alpha: MerchantColors.goldBorderAlpha),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isWritingNfc
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: MerchantColors.gold),
                          )
                        : const Icon(Icons.nfc_rounded,
                            color: MerchantColors.gold, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      _isWritingNfc
                          ? 'Approchez le badge NFC...'
                          : 'Programmer un badge NFC',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── tips card ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: MerchantColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MerchantColors.gold.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: MerchantColors.gold, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Comment l\'utiliser',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: MerchantColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _tip('Imprimez et affichez-le à la caisse'),
                _tip('Partagez-le sur vos réseaux sociaux'),
                _tip('Ajoutez-le à vos cartes de visite'),
                if (_kEnableNfcPlaquePrograming)
                  _tip('Programmez un badge NFC pour un accès sans scan')
                else
                  _tip('Demandez votre badge NFC Yuztoo à apposer à la caisse'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tip(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ',
                style: TextStyle(color: MerchantColors.textGrey, fontSize: 13)),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: MerchantColors.textGrey,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_2_rounded,
                  color: MerchantColors.textGrey, size: 48),
              const SizedBox(height: 16),
              Text(
                'Impossible de charger votre QR code',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Vérifiez votre connexion et réessayez.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: MerchantColors.textGrey),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => ref.invalidate(currentMerchantForOwnerProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Réessayer',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.bgHeader,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 50,
          decoration: outlined
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: MerchantColors.gold, width: 1.5),
                )
              : BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: MerchantColors.gold.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: outlined ? MerchantColors.gold : MerchantColors.bgHeader,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 18,
                          color: outlined
                              ? MerchantColors.gold
                              : MerchantColors.bgHeader),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: outlined
                              ? MerchantColors.gold
                              : MerchantColors.bgHeader,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
