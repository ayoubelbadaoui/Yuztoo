import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../domain/legal_document.dart';

/// Reusable scrollable legal-text screen used for both CGU and Politique
/// de Confidentialité. Single screen on purpose: same layout, same chrome,
/// content is the only thing that varies.
///
/// The text MUST always be available offline — App Store reviewers run
/// the binary on a device that may have no network at first launch and
/// will reject the app if a privacy link 404s. That is why
/// [LegalDocument] bundles its content as Dart constants instead of
/// loading from a remote URL.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final meta = document.meta;
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
            _Header(title: meta.title),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  MediaQuery.of(context).padding.bottom + 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dernière mise à jour : ${meta.lastUpdated}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: MerchantColors.textGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      meta.intro,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        height: 1.55,
                        color: MerchantColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 28),
                    for (int i = 0; i < meta.sections.length; i++) ...[
                      _SectionBlock(section: meta.sections[i]),
                      if (i < meta.sections.length - 1)
                        const SizedBox(height: 24),
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

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold.withValues(
                    alpha: MerchantColors.goldBorderAlpha),
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: MerchantColors.gold,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MerchantColors.textWhite,
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
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section});

  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.heading,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: MerchantColors.gold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          section.body,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            height: 1.55,
            color: MerchantColors.textWhite,
          ),
        ),
      ],
    );
  }
}
