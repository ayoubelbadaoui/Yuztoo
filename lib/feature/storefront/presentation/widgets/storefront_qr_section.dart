import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/config/vitrine_qr_config.dart';
import 'storefront_colors.dart';

/// "Mon QR code" block for the Accueil tab — encodes the public vitrine URL for this commerce.
class StorefrontQrSection extends StatefulWidget {
  const StorefrontQrSection({
    super.key,
    required this.merchantId,
  });

  final String merchantId;

  @override
  State<StorefrontQrSection> createState() => _StorefrontQrSectionState();
}

class _StorefrontQrSectionState extends State<StorefrontQrSection> {
  bool _saving = false;

  String get _payload => VitrineQrConfig.uriStringForMerchant(widget.merchantId);

  Future<void> _downloadQr() async {
    if (_payload.isEmpty) return;
    setState(() => _saving = true);
    try {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Autorisez l\'accès à la galerie pour enregistrer le QR code.'),
            ),
          );
        }
        return;
      }

      final result = QrValidator.validate(
        data: _payload,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
      if (!result.isValid || result.qrCode == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de générer le QR code.')),
          );
        }
        return;
      }

      final painter = QrPainter.withQr(
        qr: result.qrCode!,
        gapless: true,
      );
      final byteData = await painter.toImageData(512);
      if (byteData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de l\'export du QR code.')),
          );
        }
        return;
      }
      final bytes = byteData.buffer.asUint8List();
      await Gal.putImageBytes(bytes, name: 'yuztoo-vitrine-${widget.merchantId}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code enregistré dans la galerie.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.merchantId.isEmpty || _payload.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mon QR code',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: StorefrontColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos clients scannent ce code pour ouvrir directement la vitrine de votre commerce. '
            'Chaque commerce a son propre QR.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              height: 1.45,
              color: StorefrontColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: StorefrontColors.primaryGold.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: _payload,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: StorefrontColors.textPrimary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: StorefrontColors.textPrimary,
                ),
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _downloadQr,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined, size: 20),
              label: Text(
                _saving ? 'Enregistrement…' : 'Télécharger le QR code',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: StorefrontColors.primaryGold,
                side: const BorderSide(color: StorefrontColors.primaryGold, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
