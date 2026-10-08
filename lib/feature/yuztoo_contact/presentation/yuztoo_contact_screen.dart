import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/app_logo.dart';
import '../../../core/shared/widgets/yuztoo_tab_header.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../application/providers.dart';

/// "Yuztoo, restons proches" — how to reach Pascal and the YuzToo team.
class YuztooContactScreen extends ConsumerWidget {
  const YuztooContactScreen({super.key});

  static const _fallbackEmail = 'contact@yuztoo.com';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(yuztooContactProvider);

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
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: MerchantColors.gold,
                      ),
                    ),
                  ),
                  Flexible(
                    child: YuztooTabHeader.gradientTitle('Restons proches'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: contactAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: MerchantColors.gold),
                ),
                error: (_, __) => _ContactBody(
                  merchant: null,
                  fallbackEmail: _fallbackEmail,
                  onRetry: () => ref.invalidate(yuztooContactProvider),
                ),
                data: (merchant) => _ContactBody(
                  merchant: merchant,
                  fallbackEmail: _fallbackEmail,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactBody extends StatelessWidget {
  const _ContactBody({
    required this.merchant,
    required this.fallbackEmail,
    this.onRetry,
  });

  final Merchant? merchant;
  final String fallbackEmail;

  /// Set when loading failed: only the e-mail fallback is shown.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final m = merchant;
    final email = (m != null && m.email.isNotEmpty) ? m.email : fallbackEmail;
    final phone = m?.phone ?? '';
    final address = m == null
        ? ''
        : (m.address?.isNotEmpty ?? false)
            ? m.address!
            : m.city;
    final website = m?.websiteUrl ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      children: [
        Center(child: _Avatar(photoUrl: m?.logoUrl)),
        const SizedBox(height: 16),
        Text(
          'Pascal',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: MerchantColors.textWhite,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fondateur de Yuztoo',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: MerchantColors.gold,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Une question, une idée, un souci ? Écrivez-moi ou appelez-moi, '
          'je vous réponds personnellement.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13,
            height: 1.55,
            color: MerchantColors.textLightGrey,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: MerchantColors.navyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: MerchantColors.gold
                  .withValues(alpha: MerchantColors.goldBorderStronger),
            ),
          ),
          child: Column(
            children: [
              if (phone.isNotEmpty)
                _ContactRow(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: phone,
                  onTap: () => _launch(
                    context,
                    Uri(scheme: 'tel', path: phone.replaceAll(' ', '')),
                  ),
                ),
              _ContactRow(
                icon: Icons.mail_outline_rounded,
                label: 'E-mail',
                value: email,
                showDivider: phone.isNotEmpty,
                onTap: () => _launch(context, Uri(scheme: 'mailto', path: email)),
              ),
              if (address.isNotEmpty)
                _ContactRow(
                  icon: Icons.place_outlined,
                  label: 'Adresse',
                  value: address,
                  showDivider: true,
                  onTap: () => _launch(
                    context,
                    Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query='
                      '${Uri.encodeComponent(address)}',
                    ),
                  ),
                ),
              if (website.isNotEmpty)
                _ContactRow(
                  icon: Icons.language_outlined,
                  label: 'Site web',
                  value: website.replaceFirst(RegExp(r'^https?://'), ''),
                  showDivider: true,
                  onTap: () => _launch(
                    context,
                    Uri.parse(
                      website.startsWith('http') ? website : 'https://$website',
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 20),
          Text(
            'Impossible de charger toutes les coordonnées pour le moment.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textGrey,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Réessayer',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: MerchantColors.gold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  static Future<void> _launch(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir ce lien')),
      );
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.photoUrl});

  final String? photoUrl;

  static const double _size = 112;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: MerchantColors.gold,
      ),
      child: ClipOval(
        child: ColoredBox(
          color: MerchantColors.bgHeader,
          child: url == null || url.isEmpty
              ? const Center(child: AppLogo(size: 56))
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: AppLogo(size: 56)),
                ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.showDivider = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: MerchantColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: MerchantColors.gold),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: MerchantColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: MerchantColors.textWhite,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: MerchantColors.textGrey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
