part of 'client_profile_screen.dart';

extension _ClientProfileScreenUi on _ClientProfileScreenState {
  Widget _buildClientProfileBody(BuildContext context, AppLocalizations l10n) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarBrightness: Brightness.dark,
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
                    _buildSection(
                      sectionLabel: l10n.account,
                      items: [
                        _NavItem(
                          icon: Icons.person_outline,
                          label: l10n.personalInfo,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PersonalInformationScreen(),
                              ),
                            );
                          },
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
                final confirm = await showLogoutConfirmationDialog(context);
                if (confirm && mounted) {
                  await ref.read(authControllerProvider.notifier).signOut();
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
