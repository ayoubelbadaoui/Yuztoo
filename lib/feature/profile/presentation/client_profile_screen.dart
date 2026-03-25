import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/logout_confirm_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/core/application/providers.dart';

/// Client profile / settings – same colors and minimalist layout as merchant settings.
class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({super.key});

  static String get path => '/client-profile';

  @override
  ConsumerState<ClientProfileScreen> createState() =>
      _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgHeader,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(l10n),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                ),
                child: Column(
                  children: [
                    _buildDescription(l10n),
                    _buildProfileBlock(context),
                    _buildSection(
                      sectionLabel: l10n.account,
                      items: [
                        _NavItem(
                          icon: Icons.person_outline,
                          label: l10n.personalInfo,
                          onTap: () {},
                        ),
                        _NavItem(
                          icon: Icons.credit_card,
                          label: l10n.paymentMethods,
                          onTap: () {},
                          isLast: true,
                        ),
                      ],
                    ),
                    _buildSection(
                      sectionLabel: l10n.preferences,
                      items: [
                        _SwitchItem(
                          icon: Icons.notifications_none,
                          label: l10n.pushNotifications,
                          value: _pushEnabled,
                          onChanged: (v) =>
                              setState(() => _pushEnabled = v),
                        ),
                        _SwitchItem(
                          icon: Icons.email_outlined,
                          label: l10n.emailNotifications,
                          value: _emailEnabled,
                          onChanged: (v) =>
                              setState(() => _emailEnabled = v),
                        ),
                        _NavItem(
                          icon: Icons.settings_outlined,
                          label: l10n.settings,
                          onTap: () {},
                          isLast: true,
                        ),
                      ],
                    ),
                    _buildSection(
                      sectionLabel: l10n.support,
                      items: [
                        _NavItem(
                          icon: Icons.help_outline,
                          label: l10n.helpCenter,
                          onTap: () {},
                        ),
                        _NavItem(
                          icon: Icons.description_outlined,
                          label: l10n.termsOfUse,
                          onTap: () {},
                          isLast: true,
                        ),
                      ],
                    ),
                    _buildLogoutSection(context, l10n),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          child: Center(
            child: Text(
              l10n.myProfile,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MerchantColors.textWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Text(
          l10n.preferences,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: MerchantColors.textLightGrey,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileBlock(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: MerchantColors.gold
                      .withValues(alpha: MerchantColors.goldBorderStronger),
                  width: 1),
              color: MerchantColors.gold.withValues(alpha: 0.1),
            ),
            alignment: Alignment.center,
            child: Text(
              'M',
              style: GoogleFonts.outfit(
                color: MerchantColors.textWhite,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mohammed Ali',
                  style: GoogleFonts.outfit(
                    color: MerchantColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'mohammed@email.com',
                  style: GoogleFonts.outfit(
                    color: MerchantColors.textLightGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+212 6XX XXX XXX',
                  style: GoogleFonts.outfit(
                    color: MerchantColors.textLightGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String sectionLabel,
    required List<Widget> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionLabel.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: MerchantColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm =
                    await showLogoutConfirmationDialog(context);
                if (confirm && mounted) {
                  await ref
                      .read(authControllerProvider.notifier)
                      .signOut();
                }
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: Text(
                l10n.disconnect,
                style: GoogleFonts.outfit(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.version('1.0.0'),
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: MerchantColors.gold.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            Icon(icon, color: MerchantColors.textWhite, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: MerchantColors.textWhite,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: MerchantColors.textGrey, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
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
          Icon(icon, color: MerchantColors.textWhite, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: MerchantColors.textWhite,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: value
                    ? MerchantColors.gold
                    : const Color(0xFF444444),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
