part of 'store_profile_screen.dart';

class _StoreProfileErrorBack extends StatelessWidget {
  const _StoreProfileErrorBack({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Commerce introuvable',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: StorefrontColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: StorefrontColors.primaryGold),
            label: Text(
              'Retour',
              style: GoogleFonts.outfit(
                color: StorefrontColors.primaryGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreProfileSectionTitle extends StatelessWidget {
  const _StoreProfileSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: StorefrontColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StoreProfileInfoRow extends StatelessWidget {
  const _StoreProfileInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: StorefrontColors.primaryGold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: StorefrontColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreProfileHoursSection extends StatelessWidget {
  const _StoreProfileHoursSection({this.hours});

  final BusinessHours? hours;

  @override
  Widget build(BuildContext context) {
    final h = hours;
    if (h == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Horaires non renseignés',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: StorefrontColors.textSecondary,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: h.allDays.map((day) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day.dayName,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: StorefrontColors.textPrimary,
                  ),
                ),
                Text(
                  day.displayText,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: StorefrontColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StoreProfilePromotionsList extends StatelessWidget {
  const _StoreProfilePromotionsList({required this.promotions});

  final List<Promotion> promotions;

  @override
  Widget build(BuildContext context) {
    if (promotions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Text(
          'Aucune promotion pour le moment',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: StorefrontColors.textSecondary,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: promotions.map((promo) {
          final now = DateTime.now();
          final daysLeft = promo.dateTo.isAfter(now)
              ? promo.dateTo.difference(now).inDays
              : 0;
          final validText = daysLeft > 0
              ? 'Valide encore $daysLeft jours'
              : 'Expiré';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: StorefrontColors.cardLight,
                border: Border.all(
                  color: StorefrontColors.primaryGold.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: StorefrontColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_offer_outlined,
                      color: StorefrontColors.primaryGold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo.title,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: StorefrontColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promo.subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: StorefrontColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          validText,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: StorefrontColors.primaryGold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecordLoyaltyPassageSheet extends ConsumerStatefulWidget {
  const _RecordLoyaltyPassageSheet({
    required this.merchant,
    required this.clientUid,
    required this.needsPurchaseAmount,
  });

  final Merchant merchant;
  final String clientUid;
  final bool needsPurchaseAmount;

  @override
  ConsumerState<_RecordLoyaltyPassageSheet> createState() =>
      _RecordLoyaltyPassageSheetState();
}

class _RecordLoyaltyPassageSheetState
    extends ConsumerState<_RecordLoyaltyPassageSheet> {
  final TextEditingController _amountController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    double? purchaseAmount;
    if (widget.needsPurchaseAmount) {
      final raw = _amountController.text.replaceAll(',', '.').trim();
      purchaseAmount = double.tryParse(raw);
      if (purchaseAmount == null || purchaseAmount <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indiquez un montant valide (€)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _busy = true);
    final useCase = ref.read(recordLoyaltyPassageProvider);
    final result = await useCase.call(
      clientUid: widget.clientUid,
      merchant: widget.merchant,
      purchaseAmountEuros: purchaseAmount,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passage enregistré'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enregistrer un passage',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: StorefrontColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.needsPurchaseAmount
                  ? 'Indiquez le montant de votre achat pour mettre à jour votre fidélité.'
                  : 'Confirmez votre passage en boutique.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.45,
                color: StorefrontColors.textSecondary,
              ),
            ),
            if (widget.needsPurchaseAmount) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Montant (€)',
                  hintText: 'ex. 24,90',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: StorefrontColors.primaryGold,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: StorefrontColors.primaryGold,
                foregroundColor: StorefrontColors.navyDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: StorefrontColors.navyDark,
                      ),
                    )
                  : Text(
                      'Valider',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
extension _StoreProfileScreenUi on _StoreProfileScreenState {
  Widget _buildContent(
    BuildContext context,
    Merchant merchant,
    List<Promotion> promotions,
  ) {
    final name = merchant.displayName ?? merchant.name;
    final activity = merchant.categories?.isNotEmpty == true
        ? merchant.categories!.join(', ')
        : (merchant.city.isNotEmpty ? merchant.city : 'Commerçant');
    final hours = merchant.hours != null && merchant.hours!.isNotEmpty
        ? BusinessHours.fromMap(merchant.hours)
        : null;
    final userId = ref.watch(currentUserIdProvider);
    final followedIdsAsync =
        ref.watch(followedMerchantIdsForCurrentUserProvider);
    final heartLevelsAsync =
        ref.watch(followedMerchantHeartLevelsForCurrentUserProvider);
    final followersCountAsync = ref.watch(
followersCountByMerchantIdsProvider(<String>[merchant.id]),
    );
    final viewedIdsAsync =
        ref.watch(viewedMerchantIdsForCurrentUserProvider);
    final isFollowing = followedIdsAsync.valueOrNull?.contains(merchant.id) ?? false;
    final hasViewed = viewedIdsAsync.valueOrNull?.contains(merchant.id) ?? false;
    _markMerchantAsViewed(userId, merchant.id);
    final baseHeartLevel = isFollowing
        ? (heartLevelsAsync.valueOrNull?[merchant.id] ?? 1)
        : (hasViewed ? 1 : 0);
    final heartLevel =
        _optimisticHeartMerchantId == merchant.id && _optimisticHeartLevel != null
            ? _optimisticHeartLevel!
            : baseHeartLevel;
    final fetchedFollowersCount = followersCountAsync.valueOrNull?[merchant.id] ?? 0;
    final followersCount = isFollowing
        ? (fetchedFollowersCount < 1 ? 1 : fetchedFollowersCount)
        : fetchedFollowersCount;
    final loyaltyProgressAsync =
        ref.watch(clientLoyaltyProgressForMerchantProvider(merchant.id));

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: StorefrontColors.backgroundLight,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _followersLabelFr(followersCount),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: StorefrontColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onNotifications,
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: StorefrontColors.primaryGold,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              StoreProfileBannerSection(
                  bannerImageUrl: merchant.bannerUrl ?? merchant.logoUrl,
                  profileImageUrl: merchant.logoUrl ?? merchant.bannerUrl,
                ),
                const SizedBox(height: 56),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: StorefrontColors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                              child: Row(
                                children: List.generate(3, (index) {
                                  final target = index + 1;
                                  final isActive = heartLevel >= target;
                                  return Padding(
                                    padding: EdgeInsets.only(right: index == 2 ? 0 : 5),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: _isFollowToggling
                                          ? null
                                          : () {
                                              final nextLevel =
                                                  heartLevel == target ? target - 1 : target;
                                              _setHeartLevel(
                                                context,
                                                userId: userId,
                                                merchantId: merchant.id,
                                                level: nextLevel,
                                              );
                                            },
                                      child: Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: Icon(
                                          Icons.favorite,
                                          color: isActive
                                              ? StorefrontColors.primaryGold
                                              : StorefrontColors.textSecondary,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activity,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: StorefrontColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      _buildClientLoyaltyBlock(
                        context,
                        merchant,
                        loyaltyProgressAsync,
                        userId,
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 4),
                      _buildSuivreButton(context, merchant.id),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                NavigationTabs(
                  activeTab: _activeTab,
                  onTabChanged: _onTabChanged,
                ),
                const SizedBox(height: 20),
                if (_activeTab == 'accueil') ...[
                  if (merchant.description != null && merchant.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        merchant.description!,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.5,
                          color: StorefrontColors.textSecondary,
                        ),
                      ),
                    ),
                  if (merchant.description != null && merchant.description!.isNotEmpty)
                    const SizedBox(height: 20),
                  const _StoreProfileSectionTitle('Téléphone'),
                  _StoreProfileInfoRow(
                    icon: Icons.phone_outlined,
                    text: merchant.phone,
                  ),
                  const _StoreProfileSectionTitle('Adresse'),
                  _StoreProfileInfoRow(
                    icon: Icons.place_outlined,
                    text: merchant.address ?? merchant.city,
                  ),
                  if (promotions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _StoreProfileSectionTitle('Promotions'),
                    const SizedBox(height: 4),
                    _StoreProfilePromotionsList(promotions: promotions),
                  ],
                ] else if (_activeTab == 'horaires') ...[
                  const _StoreProfileSectionTitle('Horaires d\'ouverture'),
                  _StoreProfileHoursSection(hours: hours),
                ] else if (_activeTab == 'actualite') ...[
                  NewsSection(
                    content: merchant.description,
                    imageUrls: merchant.newsImageUrls ?? const [],
                    showMedia: merchant.newsImageUrls?.isNotEmpty ?? false,
                    showUploadButton: false,
                    contentPlaceholder: 'Aucune actualité pour le moment.',
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Même logique que la vitrine marchand : badge + texte + progression + enregistrement passage.
  Widget _buildClientLoyaltyBlock(
    BuildContext context,
    Merchant merchant,
    AsyncValue<ClientMerchantLoyaltyProgress> progressAsync,
    String? userId,
  ) {
    final summary = merchant.loyaltyClientSummaryForDisplay;
    final program = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: merchant.loyaltyEnabled);
    final canRecordPassage =
        merchant.loyaltyEnabled && program.programEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: merchant.loyaltyEnabled
                ? StorefrontColors.primaryGold.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            merchant.loyaltyEnabled ? 'Fidélité active' : 'Fidélité inactive',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: merchant.loyaltyEnabled
                  ? StorefrontColors.navyDark
                  : StorefrontColors.textSecondary,
            ),
          ),
        ),
        if (summary != null && summary.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            summary.trim(),
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: StorefrontColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
        if (canRecordPassage)
          progressAsync.when(
            data: (ClientMerchantLoyaltyProgress p) {
              final line = _loyaltyProgressSubtitle(merchant, program, p);
              if (line == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  line,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: StorefrontColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: StorefrontColors.primaryGold,
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        if (canRecordPassage) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openRecordPassageSheet(context, merchant, userId),
              style: OutlinedButton.styleFrom(
                foregroundColor: StorefrontColors.primaryGold,
                side: const BorderSide(color: StorefrontColors.primaryGold),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Enregistrer un passage',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String? _loyaltyProgressSubtitle(
    Merchant merchant,
    LoyaltyProgramConfig program,
    ClientMerchantLoyaltyProgress p,
  ) {
    if (!merchant.loyaltyEnabled || !program.programEnabled) return null;

    if (program.passageValidation == LoyaltyPassageValidation.manual) {
      if (p.pendingPassages <= 0) {
        return 'Vos passages seront validés par le commerçant.';
      }
      if (p.pendingPassages == 1) {
        return '1 passage en attente de validation par le commerçant.';
      }
      return '${p.pendingPassages} passages en attente de validation par le commerçant.';
    }

    if (program.triggerType == LoyaltyTriggerType.visitCount) {
      final need = program.visitsRequired.clamp(1, 9999);
      final v = p.validatedPassages;
      if (v >= need) {
        return 'Objectif atteint ($need passages validés).';
      }
      final remaining = need - v;
      return '$v / $need passages validés — encore $remaining avant la récompense.';
    }

    final needSpend = program.cumulativeSpendRequiredEuros;
    final spent = p.cumulativeSpendEuros;
    if (spent >= needSpend) {
      return 'Objectif d’achats atteint.';
    }
    final remain = needSpend - spent;
    final spentStr = _formatEuroDisplay(spent);
    final needStr = _formatEuroDisplay(needSpend);
    final remStr = remain == remain.roundToDouble()
        ? remain.toStringAsFixed(0)
        : remain.toStringAsFixed(2);
    return '$spentStr € / $needStr € cumulés — encore $remStr €.';
  }

  String _formatEuroDisplay(double n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }

  void _openRecordPassageSheet(
    BuildContext context,
    Merchant merchant,
    String? userId,
  ) {
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour enregistrer un passage'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final program = merchant.loyaltyProgram ??
        LoyaltyProgramConfig.fallbackFromFlags(loyaltyEnabled: merchant.loyaltyEnabled);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StorefrontColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _RecordLoyaltyPassageSheet(
          merchant: merchant,
          clientUid: userId,
          needsPurchaseAmount: program.effectiveAskClientPurchaseAmount,
        ),
      ),
    );
  }

  void _markMerchantAsViewed(String? userId, String merchantId) {
    if (userId == null || userId.isEmpty || merchantId.isEmpty) return;
    final key = '$userId::$merchantId';
    if (_lastViewedKey == key) return;
    _lastViewedKey = key;
    unawaited(
      ref
          .read(viewedMerchantsLocalServiceProvider)
          .markViewed(userId, merchantId),
    );
    ref.invalidate(viewedMerchantIdsForCurrentUserProvider);
  }

  String _followersLabelFr(int count) {
    if (count <= 1) return 'Ce commerce est suivi par $count personne';
    return 'Ce commerce est suivi par $count personnes';
  }

  Widget _buildSuivreButton(BuildContext context, String merchantId) {
    final userId = ref.watch(currentUserIdProvider);
    final followedAsync = ref.watch(followedMerchantIdsForCurrentUserProvider);
    final isFollowing = followedAsync.valueOrNull?.contains(merchantId) ?? false;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isFollowToggling
                ? null
                : () async {
                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connectez-vous pour suivre des commerces'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    _setFollowToggling(true);
                    final toggleFollow = ref.read(toggleMerchantFollowProvider);
                    final result = await toggleFollow.call(
                      userId: userId,
                      merchantId: merchantId,
                      currentlyFollowing: isFollowing,
                    );
                    if (!context.mounted) return;
                    _setFollowToggling(false);

                    if (result.isLeft) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Échec de la sauvegarde du suivi'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    ref.invalidate(followedMerchantIdsForCurrentUserProvider);
                    ref.invalidate(followedMerchantHeartLevelsForCurrentUserProvider);
                    ref.invalidate(clientHomeFeedProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFollowing
                              ? 'Vous ne suivez plus ce commerce'
                              : 'Commerce ajouté à votre carnet',
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: StorefrontColors.primaryGold,
                      ),
                    );
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: StorefrontColors.primaryGold,
              side: const BorderSide(color: StorefrontColors.primaryGold),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _isFollowToggling
                  ? '...'
                  : (isFollowing ? 'Ne plus suivre' : 'Suivre le commerce'),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications en cours - bientôt disponible'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: StorefrontColors.primaryGold,
              side: const BorderSide(color: StorefrontColors.primaryGold),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Notifications en cours',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

