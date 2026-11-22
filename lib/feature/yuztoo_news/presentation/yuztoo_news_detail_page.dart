import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/back_button.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../../core/shared/widgets/yuztoo_tab_header.dart';
import '../domain/entities/yuztoo_news.dart';

/// Full-screen Actu YuzToo — content authored from the CRM CMS.
class YuztooNewsDetailPage extends StatelessWidget {
  const YuztooNewsDetailPage({
    super.key,
    required this.news,
    this.onMerchantTap,
  });

  final YuztooNews news;
  final void Function(String merchantId)? onMerchantTap;

  Future<void> _openUrl(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(
      rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl',
    );
    if (uri == null) {
      if (context.mounted) showErrorSnackbar(context, 'Lien invalide.');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showErrorSnackbar(context, 'Impossible d\'ouvrir ce lien.');
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
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            YuztooTabHeader(
              title: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: YBackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Flexible(
                    child: YuztooTabHeader.gradientTitle('Actu Yuztoo'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTU YUZTOO',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: MerchantColors.gold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      news.title,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: MerchantColors.textWhite,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (news.hasImage) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          news.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Text(
                      news.body,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: MerchantColors.textLightGrey,
                        height: 1.55,
                      ),
                    ),
                    if (news.hasCta) ...[
                      const SizedBox(height: 28),
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
                          onPressed: () async {
                            if (news.opensMerchant) {
                              final merchantId = news.ctaMerchantId!;
                              Navigator.of(context).pop();
                              onMerchantTap?.call(merchantId);
                              return;
                            }
                            await _openUrl(context, news.ctaUrl!);
                          },
                          child: Text(
                            news.ctaLabel ?? 'En savoir plus',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
