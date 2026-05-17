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
                                builder: (_) => PersonalInformationScreen(
                                  onCreateProAccount: widget.onCreateProAccount,
                                ),
                              ),
                            );
                          },
                        ),
                        _NavItem(
                          icon: Icons.shield_outlined,
                          label: 'Sécurité & Confidentialité',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (ctx) => DataPrivacyScreen(
                                  onBack: () => Navigator.of(ctx).pop(),
                                  onAccountDeleted: () => Navigator.of(ctx).pop(),
                                ),
                              ),
                            );
                          },
                        ),
                        _NavItem(
                          icon: Icons.credit_card,
                          label: l10n.paymentMethods,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const _PaymentStubScreen(),
                              ),
                            );
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                    if (widget.isDualProfile) ...[
                      _buildSection(
                        sectionLabel: 'Mon commerce',
                        items: [
                          _NavItem(
                            icon: Icons.storefront_outlined,
                            label: 'Modifier mon profil commerçant',
                            onTap: () =>
                                widget.onNavigate?.call('pro-profile'),
                          ),
                          _NavItem(
                            icon: Icons.people_outline,
                            label: 'Tableau de bord commerçant',
                            onTap: () =>
                                widget.onNavigate?.call('switch-to-merchant'),
                            isLast: true,
                          ),
                        ],
                      ),
                    ],
                    _buildSection(
                      sectionLabel: l10n.support,
                      items: [
                        _NavItem(
                          icon: Icons.help_outline_rounded,
                          label: l10n.helpCenter,
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final url = Uri.parse('https://yuztoo.app/aide');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Centre d\'aide bientôt disponible',
                                    style: GoogleFonts.outfit(fontSize: 13),
                                  ),
                                  backgroundColor: MerchantColors.bgHeader,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                        _NavItem(
                          icon: Icons.article_outlined,
                          label: l10n.termsOfUse,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LegalDocumentScreen(
                                  document: LegalDocument.termsOfService,
                                ),
                              ),
                            );
                          },
                        ),
                        // App Store guideline 5.1.1 mandates an in-app
                        // privacy view that's reachable without leaving
                        // the app and that works offline. Pushing the
                        // bundled-text screen satisfies both — see
                        // [LegalDocument] for why content is in source.
                        _NavItem(
                          icon: Icons.privacy_tip_outlined,
                          label: l10n.privacyPolicy,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LegalDocumentScreen(
                                  document: LegalDocument.privacyPolicy,
                                ),
                              ),
                            );
                          },
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
            const Icon(Icons.chevron_right_rounded,
                color: MerchantColors.textGrey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Payment stub ─────────────────────────────────────────────────────────────

class _PaymentStubScreen extends StatelessWidget {
  const _PaymentStubScreen();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Custom top bar
              Container(
                color: MerchantColors.bgHeader,
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
                decoration: BoxDecoration(
                  color: MerchantColors.bgHeader,
                  border: Border(
                    bottom: BorderSide(
                      color: MerchantColors.gold
                          .withValues(alpha: MerchantColors.goldBorderAlpha),
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
                    const Spacer(),
                    Text(
                      'Moyens de paiement',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: MerchantColors.textWhite,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 44),
                  ],
                ),
              ), // end top bar Container
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MerchantColors.gold.withValues(alpha: 0.1),
                    border: Border.all(
                      color: MerchantColors.gold
                          .withValues(alpha: MerchantColors.goldBorderStronger),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.credit_card_rounded,
                    color: MerchantColors.gold,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Bientôt disponible',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.textWhite,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'La gestion des moyens de paiement sera disponible prochainement.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: MerchantColors.textLightGrey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
              ), // end Expanded
            ], // end Column children
          ), // end Column
        ), // end Scaffold body SafeArea
      ), // end Scaffold
    ); // end AnnotatedRegion
  }
}
