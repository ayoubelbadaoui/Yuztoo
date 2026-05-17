part of 'merchant_partners_screen.dart';

extension _PartnersUi on _MerchantPartnersScreenState {
  Widget _buildScaffold(
    BuildContext context,
    String merchantId,
    AsyncValue<List<MerchantPartner>> partnersAsync,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) widget.onBack();
        },
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: partnersAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: MerchantColors.gold,
                      strokeWidth: 2,
                    ),
                  ),
                  error: (_, __) => _buildError(),
                  data: (partners) => _buildBody(context, merchantId, partners),
                ),
              ),
            ],
          ),
          floatingActionButton: partnersAsync.hasValue
              ? _buildFab(context, merchantId)
              : null,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                onTap: widget.onBack,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: MerchantColors.gold,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Vos partenaires',
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

  Widget _buildBody(
    BuildContext context,
    String merchantId,
    List<MerchantPartner> partners,
  ) {
    final filtered = _applyTypeFilter(partners);
    return Column(
      children: [
        _buildInfoCard(),
        // Show the filter even when no partners exist YET — the merchant
        // can pre-select a sphere before tapping the FAB and the
        // selection carries through to the invite-search results.
        _buildTypeFilterRow(),
        Expanded(
          child: partners.isEmpty
              ? _buildEmptyState(context, merchantId)
              : (filtered.isEmpty
                  ? _buildFilteredEmpty()
                  : _buildPartnerList(context, merchantId, filtered)),
        ),
      ],
    );
  }

  // ── B2B/B2C filter chips ─────────────────────────────────────────────────
  // Three exclusive chips: Tous / B2B / B2C. Tapping the active one
  // does NOT clear the filter (avoids accidental dismissal mid-browse);
  // tapping Tous explicitly is the only way back to the unfiltered view.
  Widget _buildTypeFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Tous', null),
            const SizedBox(width: 8),
            _filterChip('B2C — Particuliers', 'b2c'),
            const SizedBox(width: 8),
            _filterChip('B2B — Pros', 'b2b'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _typeFilter == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _setTypeFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? MerchantColors.gold.withValues(alpha: 0.18)
              : MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? MerchantColors.gold.withValues(alpha: 0.6)
                : MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? MerchantColors.gold : MerchantColors.textGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Center(
        child: Text(
          'Aucun partenaire ne correspond à ce filtre.\n'
          'Choisissez « Tous » pour voir l\'ensemble de vos recommandations.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: MerchantColors.textGrey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MerchantColors.gold
              .withValues(alpha: MerchantColors.goldBorderAlpha),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MerchantColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.handshake_outlined,
              color: MerchantColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Recommandez des commerces de confiance. Vos clients les découvriront sur votre vitrine.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textLightGrey,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String merchantId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantColors.gold.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.handshake_outlined,
              color: MerchantColors.gold.withValues(alpha: 0.5),
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun partenaire',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invitez votre premier partenaire de confiance.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => _showInviteSheet(context, merchantId),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: MerchantColors.gold.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Inviter un partenaire',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: MerchantColors.bgHeader,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerList(
    BuildContext context,
    String merchantId,
    List<MerchantPartner> partners,
  ) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 96),
      itemCount: partners.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _PartnerCard(
        partner: partners[i],
        onDelete: () => _removePartner(merchantId, partners[i].id),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Text(
        'Impossible de charger vos partenaires.',
        style: GoogleFonts.outfit(color: MerchantColors.textGrey),
      ),
    );
  }

  Widget _buildFab(BuildContext context, String merchantId) {
    return FloatingActionButton.extended(
      onPressed: () => _showInviteSheet(context, merchantId),
      backgroundColor: MerchantColors.gold,
      foregroundColor: MerchantColors.bgHeader,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Inviter un partenaire',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _showInviteSheet(
      BuildContext context, String merchantId) async {
    final messenger = ScaffoldMessenger.of(context);
    final selected = await showModalBottomSheet<MerchantPartner?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PartnerInviteSheet(
        merchantId: merchantId,
        initialTypeFilter: _typeFilter,
      ),
    );
    if (selected != null && mounted) {
      await _invitePartner(merchantId, selected);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Invitation envoyée à ${selected.partnerName}',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: MerchantColors.gold,
          ),
        );
    }
  }
}

// ── Partner card ───────────────────────────────────────────────────────────────

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.partner, required this.onDelete});

  final MerchantPartner partner;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MerchantColors.gold
              .withValues(alpha: MerchantColors.goldBorderAlpha),
        ),
      ),
      child: Row(
        children: [
          // Logo circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantColors.gold.withValues(alpha: 0.12),
              border: Border.all(
                color:
                    MerchantColors.gold.withValues(alpha: 0.4),
              ),
            ),
            child: partner.partnerLogoUrl != null
                ? ClipOval(
                    child: Image.network(
                      partner.partnerLogoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.store_rounded,
                        color: MerchantColors.gold,
                        size: 22,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.store_rounded,
                    color: MerchantColors.gold,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        partner.partnerName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PartnerMerchantTypeBadge(type: partner.partnerMerchantType),
                  ],
                ),
                if (partner.partnerCity?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    partner.partnerCity!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.textGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (partner.isPending)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Text(
                'En attente',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
