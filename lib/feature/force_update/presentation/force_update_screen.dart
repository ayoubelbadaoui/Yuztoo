import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/app_logo.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../domain/force_update_decision.dart';

/// Full-screen hard gate — no dismiss, no back, store CTA only.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({
    super.key,
    required this.decision,
  });

  final ForceUpdateDecision decision;

  Future<void> _openStore(BuildContext context) async {
    final raw = decision.storeUrl;
    final uri = Uri.tryParse(
      raw.startsWith('http') ? raw : 'https://$raw',
    );
    if (uri == null) {
      if (context.mounted) {
        showErrorSnackbar(context, 'Lien du store invalide.');
      }
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showErrorSnackbar(context, 'Impossible d\'ouvrir le store.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const AppLogo(size: 72),
                  const SizedBox(height: 28),
                  Text(
                    'Mise à jour requise',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: MerchantColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    decision.messageFr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      height: 1.5,
                      color: MerchantColors.textLightGrey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Version installée : ${decision.installed.versionName}'
                    ' (${decision.installed.buildNumber})\n'
                    'Minimum requis : ${decision.platformMinBuild}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      height: 1.4,
                      color: MerchantColors.textGrey,
                    ),
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MerchantColors.gold,
                        foregroundColor: MerchantColors.bgMain,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _openStore(context),
                      child: Text(
                        'Mettre à jour',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
